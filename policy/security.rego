package main

import rego.v1

# C-01 — End-to-end telecommand authentication

deny contains msg if {
	input.telecommand.authentication != "end_to_end"
	msg := sprintf("[CRITICAL] C-01 | Telecommand authentication is '%s', not end_to_end | Threat: T-01", [input.telecommand.authentication])
}

deny contains msg if {
	input.telecommand.gsaas_holds_key_material
	msg := "[CRITICAL] C-01 | Ground station provider holds telecommand key material | Threat: T-01"
}

# C-02 — Authentication key storage and rotation

deny contains msg if {
	input.keys.storage != "kms"
	msg := sprintf("[CRITICAL] C-02 | Key material stored in '%s', not in a key management system | Threat: T-01", [input.keys.storage])
}

deny contains msg if {
	days_elapsed := (time.now_ns() - time.parse_rfc3339_ns(sprintf("%sT00:00:00Z", [input.keys.last_rotation]))) / 86400000000000
	days_elapsed > input.keys.rotation_days
	msg := sprintf("[HIGH] C-02 | Key rotation overdue: %d days elapsed, policy requires %d | Threat: T-01", [round(days_elapsed), input.keys.rotation_days])
}

# C-04 — Deployment integrity and pipeline privilege

deny contains msg if {
	input.deployment_pipeline.can_access_keys
	msg := "[CRITICAL] C-04 | Deployment pipeline can access telecommand key material | Threat: T-07"
}

deny contains msg if {
	not input.deployment_pipeline.artefact_signing
	msg := "[HIGH] C-04 | Build artefacts are not signed by the pipeline | Threat: T-07"
}

deny contains msg if {
	not input.deployment_pipeline.unsigned_deploy_blocked
	msg := "[HIGH] C-04 | Unsigned artefacts can be deployed to mission systems | Threat: T-07"
}

# C-05 — Operator approval separation

deny contains msg if {
	input.operations.plan_approvals_required < 2
	msg := sprintf("[CRITICAL] C-05 | Activity plans require only %d approval | Threat: T-06", [input.operations.plan_approvals_required])
}

deny contains msg if {
	input.operations.approver_can_be_author
	msg := "[CRITICAL] C-05 | A plan author can approve their own plan | Threat: T-06"
}

deny contains msg if {
	not input.operations.approval_log_append_only
	msg := "[MEDIUM] C-05 | Approval log is not append-only | Threat: T-06"
}

# C-06 — Flight rule validation of activity plans

deny contains msg if {
	not input.mission_planning.flight_rule_validation
	msg := "[CRITICAL] C-06 | Activity plans are not validated against flight rules | Threat: T-04"
}

deny contains msg if {
	input.mission_planning.validation_bypass_possible
	msg := "[CRITICAL] C-06 | Flight rule validation can be bypassed | Threat: T-04"
}

required_constraints := {"orbital_visibility", "pointing", "power_margin", "storage_margin", "contact_window_capacity"}

deny contains msg if {
	missing := required_constraints - {c | some c in input.mission_planning.validated_constraints}
	count(missing) > 0
	msg := sprintf("[HIGH] C-06 | Flight rule validation does not cover: %v | Threat: T-04", [missing])
}
