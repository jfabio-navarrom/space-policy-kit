# Reference Architecture — Vulpine-Earth Ground Segment

```mermaid
flowchart LR
    DEV[Development / Source Repo]
    D[Deployment Pipeline]
    C[Customer Portal / API]
    P[Mission Planning]
    M[Mission Control]
    G[GSaaS Provider]
    PR[Image Processing]
    A[Product Archive]
    O[Operator Access]
    S(((Satellite)))

    DEV -->|code, dependencies, config| D
    C -->|tasking requests| P
    P -->|activity plan| M
    M -->|telecommands over network| G
    G -->|S-band uplink| S
    S -->|S-band telemetry| G
    G -->|state telemetry| M
    S -->|X-band payload data| G
    G -->|raw imagery| PR
    PR -->|products| A
    A -->|catalogue| C
    O -->|approve / command| M
    D -->|deploys & configures| P
    D -->|deploys & configures| M
    D -->|deploys & configures| PR
```

## Components

### Customer Portal / API

### Mission Planning

### Mission Control

### GSaaS Provider

### Image Processing

### Product Archive

### Operator Access

### Deployment Pipeline

### Development / Source Repo
