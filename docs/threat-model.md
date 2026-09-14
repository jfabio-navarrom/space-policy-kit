ID	Component	What the attacker achieves	Mission impact	SPARTA
T-01	GSaaS Provider	Sends commands to the satellite bypassing internal approval	Satellite control	TBD
T-02	Mission Control	Issues commands to GSaaS and alters telemetry so operators see a healthy spacecraft when it is not	Satellite control, loss of detection	TBD
T-03	Product Archive	Reads, modifies or deletes catalogue products	Product integrity, commercial confidentiality	TBD
T-04	Mission Planning	Corrupts planning decisions: wrong satellite, wrong timing, or requests marked as validated without real validation	Satellite control, service disruption	TBD
T-05	Customer Portal / API	Injects tasking requests to drive satellite capture, and exfiltrates delivered products	Commercial confidentiality, misuse of capacity	TBD
T-06	Operator Access	Approves manipulated plans, or rejects legitimate ones to disrupt service	Satellite control, availability	TBD
T-07	Deployment Pipeline	Deploys altered configuration or builds to mission systems, and extracts secrets	Integrity of all deployed systems	TBD
T-08	Source Repo	Injects malicious code or dependencies, and steals source and credentials for later use	Supply chain compromise	TBD
