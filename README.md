# space-policy-kit

Policy-as-code security baseline for commercial space ground segments.

## The problem

Ground segment security is usually reviewed once per milestone. Someone
fills a spreadsheet, the review board signs it, and the file is not
opened again until the next audit. In between, the real configuration
changes and nobody checks.

The auditor should not be the one who finds out that the policy says 30
days and the key has not been rotated in a year. By then the gap has
been open for months.

At the same time, the regulatory floor is moving up. The resilience
chapter of the EU Space Act and the NIS2 Directive both apply to
commercial operators that serve European customers. A control matrix
that was correct six months ago does not satisfy either of them.

space-policy-kit writes the security requirements as executable policy.
A mission describes its own posture, and the policy evaluates it.

## How it works

1. The security posture of a mission is written in a YAML file. It
   covers link protection, key custody, operator approvals, planning
   validation, product access, and the deployment path.
2. A policy package written in Rego evaluates that file.
3. Each finding is reported with a severity, the control it belongs to,
   and the threat behind it.

Every control in this repository starts from a threat. The threats are
modelled against a reference architecture using MITRE SPARTA. Controls
that exist only because a standard mentions them are not included.

## Usage

Requires [Conftest](https://www.conftest.dev/).

```
conftest test missions/vulpine-earth-baseline.yaml
conftest test missions/vulpine-earth-remediated.yaml
```

The first mission carries realistic gaps. The second is the same mission
after remediation.

Output on the baseline mission:

```
FAIL - [CRITICAL] C-01 | Ground station provider holds telecommand key material | Threat: T-01
FAIL - [CRITICAL] C-02 | Key material stored in 'source_code', not in a key management system | Threat: T-01
FAIL - [CRITICAL] C-04 | Deployment pipeline can access telecommand key material | Threat: T-07
FAIL - [HIGH] C-02 | Key rotation overdue: 167 days elapsed, policy requires 30 | Threat: T-01

13 tests, 9 passed, 0 warnings, 4 failures, 0 exceptions
```

The last finding is the point of the project. The mission declares a
30 day rotation policy and a last rotation date. Nothing in a control
matrix compares those two values. The policy does, on every run.

## Reference mission

The policies are written against Vulpine-Earth. This is a fictional
Earth observation constellation of two satellites in sun-synchronous
orbit. It sells imagery products to European geospatial integrators
through a data API. Operations run from a cloud hosted mission
operations centre, and ground station capacity is contracted from an
external provider.

The mission is not real. It was designed to look like a small commercial
operator that falls inside EU regulatory scope. Details are in
`docs/mission-scope.md`.

## Scope

In scope: the ground segment. This means mission operations, the
telecommand and telemetry path, the interface with the contracted ground
station provider, the product archive, the customer data API, operator
access, and the pipeline that configures all of it.

Out of scope: spacecraft bus design, flight software internals, ground
station physical infrastructure, launch, inter-satellite links, and the
internal systems of the customers who buy the data.

## What this is not

- It is not a scanner. It reads a declared posture. It does not touch a
  live system.
- It does not replace an audit or threat-led penetration testing.
- It is not legal advice. The regulatory mapping is my own reading of
  published texts. Some of those texts are still in trilogue and can
  still change.

## Repository layout

```
docs/       Reference architecture, threat model, control catalogue
policy/     Rego policy package
missions/   Mission posture files
```

## Status

Nine controls are documented in `docs/control-catalog.md`. Five of them
are implemented as policy: C-01, C-02, C-04, C-05 and C-06. The
remaining four are documented but not yet executable.

The regulatory mapping is in progress.

## Author

Jose Fabio Navarro Mora
[LinkedIn](https://www.linkedin.com/in/jose-fabio-navarro-mora-a3556437/)

---

Independent research project. The reference mission is fictional. Not
affiliated with, commissioned by, or representative of confidential work
for any company, agency, or mission.
