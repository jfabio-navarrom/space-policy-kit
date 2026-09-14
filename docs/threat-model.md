| ID | Component | What the attacker achieves | Mission impact | SPARTA |
|---|---|---|---|---|
| T-01 | GSaaS Provider | Sends commands to the satellite bypassing internal approval | Satellite control | RD-0001.02 |
| T-02 | Mission Control | Issues commands to GSaaS and alters telemetry so operators see a healthy spacecraft when it is not | Satellite control, loss of detection | EX-0010 |
| T-03 | Product Archive | Reads, modifies or deletes catalogue products | Product integrity, commercial confidentiality | IMP-0005 |
| T-04 | Mission Planning | Corrupts planning decisions: wrong satellite, wrong timing, or requests marked as validated without real validation | Satellite control, service disruption | IMP-0011 |
| T-05 | Customer Portal / API | Injects tasking requests to drive satellite capture, and exfiltrates delivered products | Commercial confidentiality, misuse of capacity | REC-0009 |
| T-06 | Operator Access | Approves manipulated plans, or rejects legitimate ones to disrupt service | Satellite control, availability | IA-0004 |
| T-07 | Deployment Pipeline | Deploys altered configuration or builds to mission systems, and extracts secrets | Integrity of all deployed systems | REC-0001.01 |
| T-08 | Source Repo | Injects malicious code or dependencies, and steals source and credentials for later use | Supply chain compromise | IA-0001.01 |
