# Control Catalogue

This catalogue lists the controls derived from the threats in
`threat-model.md`. Each control exists because a specific threat exists.
None of them was taken from a standard checklist. Standards are used
later, in the regulatory mapping, to name what the analysis already
decided.

Control numbering is independent of threat numbering. One threat can
produce more than one control, and one control can address more than one
threat.

The `Mission posture field` entry of each control names the data a
mission declares in its posture file. Those fields are the input the
policy package evaluates.

---

## C-01 - End-to-end telecommand authentication

**Threat addressed:** T-01

**Requirement:** Each telecommand must include an authentication value.
Mission Control computes this value. The spacecraft checks it before it
runs the command. The key used to compute the value is held only by
Mission Control and the spacecraft. The ground station provider does not
hold this key.

**Verification:** Show that the spacecraft rejects a telecommand with no
valid authentication value. Show where the keys are held. Confirm that
the ground station provider has no access to them.

**Mission posture field:** `telecommand_authentication` (end_to_end /
provider_terminated / none), `gsaas_holds_key_material` (true / false)

**Regulatory mapping:** TBD

---

## C-02 - Authentication key storage and rotation

**Threat addressed:** T-01

**Requirement:** Authentication keys are held in a dedicated key
management system inside the MOC. Key material does not appear in source
code, configuration files, or environment variables. Keys are rotated
every 30 days, and immediately when a compromise is suspected.

**Verification:** Show the key management system and the list of roles
that can access it. Show the rotation log with dates. Show the result of
a secret scan over the source repository and the deployed configuration.

**Mission posture field:** `key_storage` (kms / config_file /
source_code), `key_rotation_days` (number), `last_key_rotation` (date),
`emergency_rotation_defined` (true / false)

**Regulatory mapping:** TBD

---

## C-03 - Source code and supply chain integrity

**Threat addressed:** T-08

**Requirement:** A change reaches the main branch only after review by a
person other than the author. Commits are cryptographically signed.
Dependency scanning and secret scanning run on every change, and a
critical finding blocks the merge.

**Verification:** Show the branch protection settings. Show a sample of
merged changes with a reviewer different from the author. Show the
scanner configuration and a run where a critical finding blocked a
merge.

**Mission posture field:** `peer_review_required` (true / false),
`signed_commits_required` (true / false), `dependency_scanning` (true /
false), `secret_scanning` (true / false)

**Regulatory mapping:** TBD

---

## C-04 - Deployment integrity and pipeline privilege

**Threat addressed:** T-07

**Requirement:** Build artefacts are signed by the pipeline. Mission
systems accept only signed artefacts, so nothing can be deployed outside
the pipeline. The pipeline runs with the minimum permissions needed to
deploy, and has no access to telecommand authentication key material.

**Verification:** Show that an unsigned artefact is rejected on
deployment. Show the permission set granted to the pipeline. Confirm the
pipeline cannot read the key management system.

**Mission posture field:** `artefact_signing` (true / false),
`unsigned_deploy_blocked` (true / false), `pipeline_can_access_keys`
(true / false)

**Regulatory mapping:** TBD

---

## C-05 - Operator approval separation

**Threat addressed:** T-06

**Requirement:** An activity plan reaches the command stage only after
approval by two operators. The operator who builds or edits a plan
cannot be one of its approvers. Every approval and every rejection is
written to an append-only log with the operator identity and the reason.

**Verification:** Show that a plan approved by a single operator does
not proceed. Show a sample of approval records with two distinct
identities. Show the rejection log and confirm operators cannot delete
entries from it.

**Mission posture field:** `plan_approvals_required` (number),
`approver_can_be_author` (true / false), `approval_log_append_only`
(true / false)

**Regulatory mapping:** TBD

---

## C-06 - Flight rule validation of activity plans

**Threat addressed:** T-04

**Requirement:** Every activity plan is validated against the mission
flight rules before it is translated into telecommands. The validation
covers at least orbital visibility of the target, pointing constraints,
on-board power and storage margins, and contact window capacity. A plan
that fails validation cannot proceed, and the validation cannot be
bypassed by any operator role.

**Verification:** Show that a plan violating a flight rule is rejected.
Show the list of rules enforced and when it was last reviewed. Confirm
no role can approve a plan that failed validation.

**Mission posture field:** `flight_rule_validation` (true / false),
`validation_bypass_possible` (true / false), `validated_constraints`
(list)

**Regulatory mapping:** TBD

---

## C-07 - Customer request rule validation and product access management

**Threat addressed:** T-05

**Requirement:** Every tasking request is authenticated and validated
against the customer's contract before it enters mission planning.
Validation covers the permitted geographic areas, the product types, and
a limit on request volume per period. A customer can retrieve only the
products generated for that customer.

**Verification:** Show that a request outside the contracted area or
above the volume limit is rejected. Show that a customer cannot retrieve
a product belonging to another customer. Show the rate limit
configuration on the API.

**Mission posture field:** `request_contract_validation` (true / false),
`request_rate_limit` (number per period), `product_access_isolation`
(true / false)

**Regulatory mapping:** TBD

---

## C-08 - Product archive integrity and deletion control

**Threat addressed:** T-03

**Requirement:** Each product has an integrity value recorded when it is
stored and verified when it is delivered. Deleting a product requires
approval from a second authorised person. Every read, modification and
deletion is written to an append-only log that archive administrators
cannot alter or remove. Access to products is granted per customer
account, not to the full catalogue.

**Verification:** Show that a product altered in storage fails integrity
verification on delivery. Show a deletion record with two distinct
identities. Confirm the archive administrator role cannot delete log
entries. Show that an account can list only its own products.

**Mission posture field:** `product_integrity_verification` (true /
false), `deletion_requires_second_approval` (true / false),
`access_log_append_only` (true / false), `catalogue_access_scope`
(per_customer / full)

**Regulatory mapping:** TBD

---

## C-09 - Telemetry reconciliation against independent sources

**Threat addressed:** T-02

**Requirement:** The commands recorded as sent by Mission Control are
reconciled against the on-board command counter reported in telemetry,
and against the contact records provided by the ground station provider.
Any discrepancy raises an alert to a recipient outside the Mission
Control system. Raw telemetry is archived in immutable storage, separate
from the system that displays it.

**Verification:** Show a reconciliation run and its output. Show that an
injected discrepancy raises an alert. Confirm that Mission Control
administrators cannot modify the archived raw telemetry.

**Mission posture field:** `telemetry_reconciliation` (true / false),
`reconciliation_sources` (list), `raw_telemetry_immutable` (true /
false), `alert_destination` (external / internal)

**Regulatory mapping:** TBD
