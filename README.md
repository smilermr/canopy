# Canopy Network

**Official Go implementation of the Canopy Network protocol.**

Canopy is a blockchain network designed around a modular protocol architecture, with an emphasis on verifiable state transitions, validator operations, networking, and production-grade node software.

> **Launch status:** This repository is being prepared for a production launch. Treat network parameters, genesis configuration, validator keys, and release artifacts as security-critical.

## Repository status

- **Language:** Go
- **Go version:** 1.24+
- **Default branch:** `main`
- **Module:** `github.com/canopy-network/canopy`
- **License:** See `LICENSE`

## Quick start

### Prerequisites

Install:

- Go 1.24 or newer
- Git
- Docker and Docker Compose (recommended for reproducible local environments)

Verify your Go installation:

```bash
go version
```

### Build

```bash
go build ./...
```

### Test

Run the complete test suite before every release candidate:

```bash
go test ./...
```

For race detection where supported:

```bash
go test -race ./...
```

## Production launch checklist

Before declaring a network release production-ready, verify all of the following:

- [ ] Genesis file has been reviewed and checksummed.
- [ ] Chain/network identifiers are correct for the target environment.
- [ ] Validator keys are generated, backed up securely, and never committed.
- [ ] Seed/bootnode endpoints have been independently verified.
- [ ] RPC/API endpoints are bound according to the intended security model.
- [ ] Public-facing services are protected by appropriate network controls.
- [ ] Monitoring, metrics, logs, and alerting are operational.
- [ ] Database/storage paths have sufficient capacity and backup procedures.
- [ ] Release binaries are built reproducibly and checksummed.
- [ ] Fresh-node synchronization has been tested from the published genesis.
- [ ] Restart, upgrade, rollback, and recovery procedures have been tested.
- [ ] Consensus and cryptographic code has received dedicated review.
- [ ] No private keys, credentials, local paths, or development secrets are present in the repository.

## Configuration and security

Never commit:

- validator private keys
- mnemonic phrases
- API credentials
- cloud credentials
- production secrets
- machine-specific configuration containing sensitive information

Use environment-specific configuration outside version control and apply the principle of least privilege to node, RPC, database, and monitoring access.

Do not change consensus-critical parameters as part of routine documentation or infrastructure maintenance. Such changes require an explicit network upgrade plan and coordinated validator testing.

## Development workflow

Run formatting and tests before opening a pull request:

```bash
gofmt -w .
go test ./...
go vet ./...
```

Keep changes focused and reviewable. Consensus, cryptography, networking, storage, and protocol changes should include targeted tests and a clear migration or compatibility note when applicable.

## Release process

A production release should include:

1. A reviewed version tag.
2. Reproducible build instructions.
3. Published SHA-256 checksums for release artifacts.
4. Release notes describing protocol, configuration, and compatibility changes.
5. Verified genesis/network configuration.
6. A documented upgrade and rollback procedure.
7. A clean-node synchronization test.

## Architecture

The codebase contains the implementation of the Canopy Network protocol and its supporting node infrastructure. When working on protocol behavior, preserve deterministic state transitions and validate changes across independent nodes before release.

For architecture and protocol-specific documentation, use the repository documentation and source code as the authoritative references.

## Contributing

1. Create a focused branch from `main`.
2. Make the smallest safe change that solves the problem.
3. Add or update tests.
4. Run formatting, tests, and static checks locally.
5. Open a pull request with a clear description of the risk and expected behavior.

Security-sensitive issues should be reported privately rather than disclosed through a public issue.

## Disclaimer

This software is provided for development and network operation purposes. Production deployment should only occur after the target network configuration, security model, consensus parameters, and release artifacts have been independently reviewed.
