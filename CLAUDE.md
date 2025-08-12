# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a demonstration Helm chart for fake-service that is distributed with Replicated Embedded Cluster. It showcases integration between Helm charts and Replicated's platform for Kubernetes application deployment.

## Development Commands

### Dagger-based Development Workflow
This project uses Dagger for CI/CD operations:

```bash
# Create a new Replicated release and promote to channel
make bump VERSION=0.0.1 CHANNEL=stable

# Reproduce a specific release configuration
make reproducing VERSION=0.0.1 CHANNEL=appen-123

# Download license file for testing
make download-license

# Create a CMX VM for testing
make create-cmx-vm

# Get install command for embedded cluster
make install-guide
```

### Dagger Commands (Direct)
```bash
# Lint the Helm chart
dagger call lint

# Package the Helm chart
dagger call package --version 0.0.1

# Create a Replicated release
dagger call create-replicated-release --token=env://REPLICATED_API_TOKEN --version=0.0.1 --channel=stable

# Download a license for testing
dagger call download-license --token=env://REPLICATED_API_TOKEN --channel=stable export --path=./license.yaml
```

### Helm Operations
```bash
# Lint chart locally (if Helm is installed)
helm lint fake-service/

# Template the chart to see generated YAML
helm template fake-service fake-service/

# Install chart locally for testing
helm install fake-service fake-service/
```

## Architecture

### Repository Structure
- **`fake-service/`**: Main Helm chart directory containing standard Helm chart structure
- **`replicated/`**: Replicated-specific manifests for KOTS/Embedded Cluster deployment
- **`dagger/`**: Dagger module written in Go for CI/CD automation

### Key Components

#### Helm Chart (`fake-service/`)
- Standard Kubernetes application chart using nginx as base image
- Includes common Kubernetes resources: Deployment, Service, Ingress, HPA, ServiceAccount
- Depends on Replicated's library chart for SDK integration
- Chart version and app version are managed separately

#### Replicated Integration (`replicated/`)
- **`kots-chart.yaml`**: HelmChart CR that tells KOTS how to deploy the Helm chart
- **`kots-app.yaml`**: Application metadata and configuration
- **`kots-config.yaml`**: Configuration options for end users
- **`kots-ec.yaml`**: Embedded Cluster specific configuration
- **`kots-preflight.yaml`**: Pre-installation checks
- **`backup.yaml`**: Backup and restore configuration

#### Dagger Module (`dagger/`)
- Go-based Dagger module (`HelmFakeService` struct)
- Integrates with Replicated vendor CLI for release management
- Handles Helm chart packaging, linting, and version management
- Automates license generation and download for testing

### Build and Release Process
1. **Lint**: Helm chart is linted using Dagger's Helm integration
2. **Package**: Chart is packaged with version and dependency updates
3. **Update Manifests**: KOTS HelmChart CR is updated with new chart version
4. **Create Release**: Replicated release is created with all manifests
5. **License Generation**: Customer and license are created for testing

## Configuration

### Environment Variables
- `REPLICATED_API_TOKEN`: Required for Replicated vendor CLI operations
- `VERSION`: Chart and app version (default: 0.0.1)
- `CHANNEL`: Release channel (default: current git branch)
- `APP_SLUG`: Replicated app slug (default: gerard-helm-fake-service)

### Versioning Strategy
- Chart versions are managed in `fake-service/Chart.yaml`
- Dagger automatically appends timestamp to versions during packaging
- KOTS HelmChart CR version is automatically synchronized during release

### Dependencies
- Replicated library chart (v1.7.1) for SDK integration
- Dagger dependencies: git-info, helm, replicated modules
- Base container images: Alpine Linux, nginx

## Troubleshooting Features

The repository includes utilities for debugging KOTS Admin Console:

### Database Access (rqlite)
```bash
kubectl port-forward svc/rqlite-ui-service 3000:80
# Browse to http://localhost:3000
```

### Object Storage Access (Minio)
```bash
# Get WebUI port from logs
kubectl logs kotsadm-minio-0

# Port forward to WebUI
kubectl port-forward svc/kotsadm-minio <port>:<port>

# Login with admin/secretkey from kotsadm-minio secret
```