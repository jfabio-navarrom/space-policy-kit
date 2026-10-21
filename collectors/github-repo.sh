#!/usr/bin/env bash
#
# Collects the real state of a GitHub repository through the API and writes
# it as a mission posture file.
#
# A fact the collector cannot observe is recorded as "unknown" or as an
# empty sample, never as a pass. The policy reports those as coverage
# warnings, so a missing permission can never look like compliance.
#
# Usage: collectors/github-repo.sh [owner/repo] > missions/live.json

set -uo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-}}"
WINDOW_DAYS=30
BOT_NAME="control-monitor"

if [ -z "$REPO" ]; then
	echo "usage: $0 owner/repo" >&2
	exit 2
fi

# --- commits: is each one cryptographically signed? ----------------------
#
# The window is a period, not a count. A count window silently shrinks when
# activity spikes: twenty commits can be one afternoon or six months, and
# "the last twenty are signed" then says nothing about the month.
#
# The monitor's own commits are excluded. They are signed by the platform,
# so leaving them in would let the monitor dilute the very measurement it
# exists to take.
SINCE=$(date -u -d "$WINDOW_DAYS days ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)
RAW=$(gh api "repos/$REPO/commits?since=$SINCE&per_page=100" 2>/dev/null || echo '[]')
COMMITS=$(echo "$RAW" | jq --arg bot "$BOT_NAME" \
  '[.[] | select(.commit.author.name != $bot)]' 2>/dev/null || echo '[]')
COMMITS_SAMPLED=$(echo "$COMMITS" | jq 'length' 2>/dev/null || echo 0)
COMMITS_UNSIGNED=$(echo "$COMMITS" | jq '[.[] | select(.commit.verification.verified != true)] | length' 2>/dev/null || echo 0)
COMMITS_EXCLUDED=$(echo "$RAW" | jq --arg bot "$BOT_NAME" \
  '[.[] | select(.commit.author.name == $bot)] | length' 2>/dev/null || echo 0)

# --- merges: approved by someone other than the author? ------------------
PULLS=$(gh api "repos/$REPO/pulls?state=closed&per_page=30" 2>/dev/null || echo '[]')
MERGES_SAMPLED=0
MERGES_UNREVIEWED=0

for n in $(echo "$PULLS" | jq -r '.[] | select(.merged_at != null) | .number' 2>/dev/null); do
	MERGES_SAMPLED=$((MERGES_SAMPLED + 1))
	AUTHOR=$(echo "$PULLS" | jq -r --argjson n "$n" '.[] | select(.number == $n) | .user.login')
	APPROVALS=$(gh api "repos/$REPO/pulls/$n/reviews" 2>/dev/null |
		jq --arg a "$AUTHOR" '[.[] | select(.state == "APPROVED" and .user.login != $a)] | length' 2>/dev/null)
	[ -z "$APPROVALS" ] && APPROVALS=0
	[ "$APPROVALS" -eq 0 ] && MERGES_UNREVIEWED=$((MERGES_UNREVIEWED + 1))
done

# --- secret scanning: repository security settings -----------------------
SECRET_SCANNING=$(gh api "repos/$REPO" 2>/dev/null |
	jq -r '.security_and_analysis.secret_scanning.status // "unknown"' 2>/dev/null)
[ -z "$SECRET_SCANNING" ] && SECRET_SCANNING="unknown"

# --- dependabot alerts ---------------------------------------------------
ALERTS=$(gh api "repos/$REPO/dependabot/alerts?state=open&per_page=100" 2>/dev/null |
	jq 'length' 2>/dev/null)
[ -z "$ALERTS" ] && ALERTS='"unknown"'

cat <<EOF
{
  "mission": "space-policy-kit",
  "collected_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "source": "github-api:$REPO",
  "source_control": {
    "window_days": $WINDOW_DAYS,
    "commits_sampled": $COMMITS_SAMPLED,
    "commits_unsigned": $COMMITS_UNSIGNED,
    "commits_excluded_bot": $COMMITS_EXCLUDED,
    "merges_sampled": $MERGES_SAMPLED,
    "merges_unreviewed": $MERGES_UNREVIEWED,
    "secret_scanning": "$SECRET_SCANNING",
    "dependabot_alerts_open": $ALERTS
  }
}
EOF
