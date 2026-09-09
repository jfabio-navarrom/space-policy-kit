# OrbitGate

Policy-as-code security baseline for commercial space ground segments.

## The problem

Ground segment security is usually reviewed once per milestone. Someone
fills a spreadsheet, the review board signs it, and the file is not
opened again until the next audit. In between, the real configuration
changes and nobody checks.

At the same time, the regulatory floor is moving up. The resilience
chapter of the EU Space Act and the NIS2 Directive both apply to
commercial operators that serve European customers. A control matrix
that was correct six months ago does not satisfy either of them.

OrbitGate writes the security requirements as executable policy. A
mission describes its own posture, and the policy evaluates it.

## How it works

1. The security posture of a mission is written in a YAML file. It
   covers link protection, ground station provider arrangements,
   operator access, product archive controls, and similar items.
2. A policy package written in Rego evaluates that file.
3. Each finding is reported with a severity, the threat it relates to,
   and the regulatory clause behind it.

Every rule in this repository starts from a threat. The threats are
modelled against a reference architecture using MITRE SPARTA. Rules that
exist only because a standard mentions them are not included.

## Usage

Requires [Conftest](https://www.conftest.dev/).

make check-baseline # mission with known gaps
make check-remediated # same mission after remediation


Both targets call Conftest directly:

conftest test missions/vulpine-earth-baseline.yaml --policy policy/


Example output:

FAIL - missions/vulpine-earth-baseline.yaml

[CRITICAL] OG-003 Payload downlink encryption
Component : X-band downlink
Finding : Link layer encryption is not enabled
Threat : Interception of imagery products in transit
Reference : [pendiente semana 6]


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

docs/ Reference architecture, threat model, control catalogue
policy/ Rego policy package
missions/ Mission posture files
tests/ Policy unit tests


## Status

Architecture and threat modelling. The policy package is not written yet. This README describes the intended design.

## Author

Jose Fabio Navarro Mora
[LinkedIn](https://www.linkedin.com/in/jose-fabio-navarro-mora-a3556437/)

---

Independent research project. The reference mission is fictional. Not
affiliated with, commissioned by, or representative of confidential work
for any company, agency, or mission.
