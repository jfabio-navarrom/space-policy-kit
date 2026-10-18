#!/usr/bin/env bash
#
# Raises an alert when a control starts failing and clears it when the
# control recovers.
#
# The open issue IS the state: there is no separate store, and a control
# that stays broken does not alert again every day. That is what keeps the
# alerts worth reading.
#
set -uo pipefail
LABEL="control-failure"
OPEN=$(gh issue list --state open --label "$LABEL" --json number,title 2>/dev/null || echo '[]')

jq -c '.controls[]' site/status.json | while read -r c; do
	ID=$(echo "$c" | jq -r '.id')
	NAME=$(echo "$c" | jq -r '.name')
	ST=$(echo "$c" | jq -r '.status')
	SRC=$(echo "$c" | jq -r '.source')
	TITLE="Control failing: $ID — $NAME"
	NUM=$(echo "$OPEN" | jq -r --arg t "$TITLE" '.[] | select(.title == $t) | .number' | head -1)

	if [ "$ST" = "fail" ]; then
		if [ -n "$NUM" ]; then
			echo "$ID: ya abierta #$NUM, sin repetir"
		else
			BODY=$(echo "$c" | jq -r '"Source: " + .source + "\n\n**Findings**\n" + (.findings | map("- " + .) | join("\n"))')
			gh issue create --title "$TITLE" --label "$LABEL" --body "$BODY" >/dev/null
			echo "$ID: ALERTA ABIERTA ($SRC)"
		fi
	else
		if [ -n "$NUM" ]; then
			gh issue close "$NUM" --comment "Control recovered." >/dev/null
			echo "$ID: recuperado, cerrada #$NUM"
		else
			echo "$ID: ok"
		fi
	fi
done
