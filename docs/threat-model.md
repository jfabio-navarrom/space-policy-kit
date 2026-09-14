# Threat Model

This threat model covers the ground segment of the Vulpine-Earth
reference architecture. The space segment, the satellite bus and flight
software are out of scope. Each component was reviewed to identify what
an attacker would achieve by controlling it, and each threat is mapped
to a technique from the SPARTA matrix.

The main finding is that link encryption does not stop any of the eight threats
listed below. All of them remain possible on a mission where the
telecommand link is correctly encrypted and authenticated.

The reason is that several of these threats do not forge anything. They
corrupt legitimate authority instead. A manipulated activity plan, a
compromised deployment pipeline, or stolen operator credentials all
produce commands that are well formed, correctly signed, and accepted by
the spacecraft. What is corrupted is the decision, not the message. The
remaining threats target data at rest or availability of the service,
which the link protocol does not cover either.

Link encryption is necessary. It is not sufficient. The controls derived
from this model are listed in `control-catalog.md`.

| ID | Component | What the attacker achieves | Mission impact | SPARTA |
|---|---|---|---|---|
| T-01 | GSaaS Provider | Sends commands to the satellite bypassing internal approval | Satellite control | RD-0001.02 |
| T-02 | Mission Control | Issues commands to GSaaS and alters telemetry so operators see a healthy spacecraft when it is not | Satellite control, loss of detection | EX-0010 |
| T-03 | Product Archive | Reads, modifies or deletes catalogue products | Product integrity, commercial confidentiality | IMP-0005 |
| T-04 | Mission Planning | Corrupts planning decisions: wrong satellite, wrong timing, or requests marked as validated without real validation | Satellite control, service disruption | IMP-0011 |
| T-05 | Customer Portal / API | Injects tasking requests to drive satellite capture, and exfiltrates delivered products | Commercial confidentiality, misuse of capacity | IA-0001 / EX-0009 |
| T-06 | Operator Access | Approves manipulated plans, or rejects legitimate ones to disrupt service | Satellite control, availability | IA-0004 |
| T-07 | Deployment Pipeline | Deploys altered configuration or builds to mission systems, and extracts secrets | Integrity of all deployed systems | IA-0001.02 |
| T-08 | Source Repo | Injects malicious code or dependencies, and steals source and credentials for later use | Supply chain compromise | IA-0001.01 |
