package live

import rego.v1

# C-03 — Source code and supply chain integrity
#
# This control is evaluated against facts collected from the GitHub API,
# not against a declared posture. A fact the collector could not observe
# is reported as a warning, never as a pass.

sc := input.source_control

# --- observed violations -------------------------------------------------

deny contains msg if {
	is_number(sc.commits_unsigned)
	sc.commits_unsigned > 0
	msg := sprintf("[HIGH] C-03 | %d of the last %d commits on the default branch are not signed | Threat: T-08", [sc.commits_unsigned, sc.commits_sampled])
}

deny contains msg if {
	is_number(sc.merges_unreviewed)
	sc.merges_unreviewed > 0
	msg := sprintf("[HIGH] C-03 | %d of the last %d merges reached the default branch without an approval from someone other than the author | Threat: T-08", [sc.merges_unreviewed, sc.merges_sampled])
}

deny contains msg if {
	sc.secret_scanning == "disabled"
	msg := "[CRITICAL] C-03 | Secret scanning is disabled on the repository | Threat: T-08"
}

deny contains msg if {
	is_number(sc.dependabot_alerts_open)
	sc.dependabot_alerts_open > 0
	msg := sprintf("[HIGH] C-03 | %d open Dependabot alerts on the repository | Threat: T-08", [sc.dependabot_alerts_open])
}

# --- coverage gaps: observed nothing, which is not the same as passing ----

warn contains msg if {
	sc.secret_scanning == "unknown"
	msg := "[COVERAGE] C-03 | Secret scanning state could not be observed; the collector lacks permission to read it"
}

warn contains msg if {
	sc.dependabot_alerts_open == "unknown"
	msg := "[COVERAGE] C-03 | Dependabot alert count could not be observed; the collector lacks permission to read it"
}

warn contains msg if {
	sc.merges_sampled == 0
	msg := "[COVERAGE] C-03 | No merged pull requests in the sample window, so peer review could not be observed"
}
