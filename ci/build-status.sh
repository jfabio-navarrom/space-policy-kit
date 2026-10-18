#!/usr/bin/env bash
#
# Merges every control evaluation into one status document.
#
# Two kinds of control live here and the difference is recorded, never
# blurred: a DECLARED control is evaluated against a posture file a person
# wrote; an OBSERVED control is evaluated against facts a collector read
# from a real system. Only the second kind is evidence.

set -uo pipefail

REPO="${GITHUB_REPOSITORY:-unknown/unknown}"
NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
OUT="${1:-site/status.json}"
mkdir -p "$(dirname "$OUT")"

# status_of <control-id> <result-file>  ->  pass | fail
status_of() {
	local id="$1" file="$2"
	if jq -e --arg id "$id" '[.[] | .failures[]?.msg] | map(select(contains($id))) | length > 0' "$file" >/dev/null 2>&1; then
		echo fail
	else
		echo pass
	fi
}

# json array of messages mentioning <control-id>, from <key> of <result-file>
msgs_of() {
	local id="$1" key="$2" file="$3"
	jq -c --arg id "$id" --arg k "$key" \
		'[.[] | .[$k][]?.msg] | map(select(contains($id)))' "$file" 2>/dev/null || echo '[]'
}

CONTROLS_JSON="[]"

add_control() {
	local id="$1" name="$2" source="$3" file="$4"
	local st findings gaps
	st=$(status_of "$id" "$file")
	findings=$(msgs_of "$id" failures "$file")
	gaps=$(msgs_of "$id" warnings "$file")
	CONTROLS_JSON=$(echo "$CONTROLS_JSON" | jq -c \
		--arg id "$id" --arg name "$name" --arg source "$source" --arg st "$st" \
		--argjson f "$findings" --argjson g "$gaps" \
		'. + [{id: $id, name: $name, source: $source, status: $st, findings: $f, coverage_gaps: $g}]')
}

# --- declared controls, evaluated against the reference mission file
while IFS='|' read -r id name || [ -n "$id" ]; do
	[ -z "$id" ] && continue
	add_control "$id" "$name" declared mission-result.json
done <policy/controls.txt

# --- observed controls, evaluated against facts collected from a real system
add_control "C-03" "Source code and supply chain integrity" observed live-result.json

jq -n \
	--arg at "$NOW" --arg repo "$REPO" --argjson c "$CONTROLS_JSON" \
	'{
		generated_at: $at,
		repo: $repo,
		controls: ($c | sort_by(.id)),
		summary: {
			total: ($c | length),
			failing: ($c | map(select(.status == "fail")) | length),
			observed: ($c | map(select(.source == "observed")) | length),
			coverage_gaps: ($c | map(.coverage_gaps | length) | add)
		}
	}' >"$OUT"

cat "$OUT"
