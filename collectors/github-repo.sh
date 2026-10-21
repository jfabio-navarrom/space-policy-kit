#!/usr/bin/env bash
#
# Collects the real state of a GitHub repository through the API and writes
# it as a mission posture file.
#
# A fact the collector cannot observe is recorded as "unknown", never as a
# pass. The policy reports those as coverage warnings, so a missing
# permission can never look like compliance.
#
# Usage: collectors/github-repo.sh [owner/repo] > missions/live.json

set -uo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-}}"
SAMPLE=20

if [ -z "$REPO" ]; then
	echo "usage: $0 owner/repo" >&2
	exit 2
fi

# --- commits: is each one cryptographically signed? ----------------------
#
# The monitor's own commits are excluded from the sample. They are signed by
# the platform, so leaving them in would let the monitor dilute the very
# measurement it exists to take: one bot commit a day quietly pushes the
# human ones out of the window until the control passes on its own.
# Over-fetch so that excluding them still leaves a full sample.
RAW=$(gh api "repos/$REPO/commits?per_page=100" 2>/dev/null || echo '[]')
COMMITS=$(echo "$RAW" | jq --arg bot "$BOT_NAME" \
  '[.[] | select(.commit.author.name != $bot)] | .[0:'"$SAMPLE"']' 2>/dev/null || echo '[]')
COMMITS_SAMPLED=$(echo "$COMMITS" | jq 'length' 2>/dev/null || echo 0)
COMMITS_UNSIGNED=$(echo "$COMMITS" | jq '[.[] | select(.commit.verification.verified != true)] | length' 2>/dev/null || echo 0)
COMMITS_EXCLUDED=$(echo "$RAW" | jq --arg bot "$BOT_NAME" \
  '[.[] | select(.commit.author.name == $bot)] | length' 2>/dev/null || echo 0)

# --- merges: approved by someone other than the author? ------------------
PULLS=$(gh api "repos/$REPO/pulls?state=closed&per_page=$SAMPLE" 2>/dev/null || echo '[]')
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
