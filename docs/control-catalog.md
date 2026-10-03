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

## A note on the regulatory mapping

Three sources are used, and they do different things.

NIS2 sets the general obligation. Article 21(2) lists the minimum risk
management measures an essential or important entity must take, in broad
terms: cryptography, access control, supply chain, incident handling.

The EU Space Act, Title IV Chapter II (Articles 74-95), sets the
space-specific resilience regime. For space operators that fall under
points (8) and (11) of Annex I of NIS2, this chapter applies as lex
specialis: those operators follow the Space Act resilience chapter
instead of the NIS2 measures, to avoid duplicate requirements. So for an
in-scope operator the two are not parallel obligations. The Space Act
displaces NIS2 on the matters it covers. The proposal is still in
trilogue and the text may change.

Neither of them says how. CCSDS standards do, but only for what happens
on the link. Where a control has no CCSDS reference, that is not an
omission in this catalogue. It reflects that most of the ground segment
risk sits outside what the space link standards cover.

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

**Regulatory mapping:** NIS2 Art. 21(2)(j) - requires authentication measures within the entity. The text is written for human access, so the obligation applies by principle rather than by letter: this control authenticates a machine-to-machine command link. EU Space Act Title IV Chapter II (Arts. 74-95) - requires implementation of cryptography as part of the risk management regime for space infrastructure; as lex specialis, it displaces the NIS2 measures for in-scope space operators. Still in trilogue. CCSDS 355.0-B §2.2.4 - the Security Service for TC applies authentication to the Transfer Frame Data Field of a telecommand frame, which is the mechanism this control requires.

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

**Regulatory mapping:** NIS2 Art. 21(2)(h) - requires policies on cryptography and encryption. The text covers the obligation to have a cryptographic policy, but does not detail key lifecycle, rotation intervals or custody. EU Space Act Title IV Chapter II (Arts. 74-95) - requires implementation of cryptography within the space-specific risk management regime; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS 354.0-M-1 - recommended practice for symmetric key management, covering key lifecycle states, storage and operational lifetime limits. Note: this is a Magenta Book (recommended practice), not a normative Blue Book.

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

**Regulatory mapping:** NIS2 Art. 21(2)(d) - requires supply chain security, including the relationships between an entity and its direct suppliers and service providers. EU Space Act Title IV Chapter II (Arts. 74-95) - covers this control through the general requirement for all-hazard risk management across the full mission lifecycle, including design and manufacturing. The chapter does not address software supply chain or development lifecycle specifically, so NIS2 remains the more precise reference here. Still in trilogue. CCSDS - no applicable standard. Ground segment software development sits outside the scope of the space link standards.

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

**Regulatory mapping:** NIS2 Art. 21(2)(e) and (i) - Art. 21(2)(e) requires security in network and information systems acquisition, development and maintenance, ensuring deployment processes protect against unauthorized changes; Art. 21(2)(i) covers access control policies, supporting the least-privilege permissions required for the pipeline. EU Space Act Title IV Chapter II (Arts. 74-95) - requires strict access control and all-hazard risk management measures across the mission lifecycle; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS: No direct standard (deployment pipelines and infrastructure access controls are handled through general ground segment engineering practices).

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

**Regulatory mapping:** NIS2 Art. 21(2)(i) - requires policies on human resources security, access control policies, and asset management, which supports the requirement for separation of duties and dual-operator authorization. EU Space Act Title IV Chapter II (Arts. 74-95) - requires strict access control and all-hazard risk management measures across the mission lifecycle; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS: No direct standard (dual-operator authorization workflows occur inside the Mission Control Center rather than over the space link).

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

**Regulatory mapping:** NIS2: No direct mapping (NIS2 does not address operational pre-execution validation or flight rule checks, as this is a domain-specific prevention control that goes beyond general frameworks). EU Space Act Title IV Chapter II (Arts. 74-95) - requires all-hazard risk management measures across the mission lifecycle to ensure operational safety; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS: No direct standard (mission planning logic and flight rule verification are internal ground segment functions).

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

**Regulatory mapping:** NIS2 Art. 21(2)(i) - requires access control policies and asset management to ensure proper data isolation and user access limits. EU Space Act Title IV Chapter II (Arts. 74-95) - requires strict access control and all-hazard risk management measures across the mission lifecycle; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS: No direct standard (payload data distribution and customer portals reside in the ground data segment).

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

**Regulatory mapping:** NIS2 Art. 21(2)(c) and (i) - Art. 21(2)(c) covers data security and integrity measures, while Art. 21(2)(i) covers access control policies and secure asset management. EU Space Act Title IV Chapter II (Arts. 74-95) - requires strict access control and all-hazard risk management measures across the mission lifecycle; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS: No direct standard (archive management and product databases are handled via ground data systems).

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

**Regulatory mapping:** NIS2 Art. 21(2)(b) - relates to incident handling (as telemetry reconciliation serves to detect anomalies and ongoing discrepancies that require handling). EU Space Act Title IV Chapter II (Arts. 74-95) - requires all-hazard risk management measures across the mission lifecycle to support operational monitoring; applies as lex specialis for in-scope operators. Still in trilogue. CCSDS: No direct standard (reconciliation occurs strictly on the ground between independent system records, entirely outside the space link).
