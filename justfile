# Default values for variables
VERSION := "0.0.1"
# Use CHANNEL env var if set, otherwise fall back to the current git branch.
# You can also override on the CLI: just CHANNEL=stable create-release
CHANNEL := env_var_or_default("CHANNEL", `git rev-parse --abbrev-ref HEAD`)
# Use APP_SLUG env var if set, otherwise default to gerard-helm-fake-service.
APP_SLUG := env_var_or_default("APP_SLUG", "gerard-helm-fake-service")
# Export REPLICATED_APP for use by the replicated CLI.
export REPLICATED_APP := "gerard-helm-fake-service"
CHART_DIR := "fake-service"
REPLICATED_DIR := "replicated"
RELEASE_TMP := ".release-tmp"

# List available recipes
[private]
default:
    @just --list

# Lint the Helm chart
lint:
    helm lint {{CHART_DIR}}

# Package the Helm chart with dependencies
package version=VERSION:
    helm dependency update {{CHART_DIR}}
    helm package {{CHART_DIR}} --version {{version}} --app-version {{version}}

# Prepare the release directory: update kots-chart.yaml version and copy manifests + packaged chart
prepare-release version=VERSION: (package version)
    rm -rf {{RELEASE_TMP}}
    mkdir -p {{RELEASE_TMP}}
    cp {{REPLICATED_DIR}}/* {{RELEASE_TMP}}/
    yq -i '.spec.chart.chartVersion = "{{version}}"' {{RELEASE_TMP}}/kots-chart.yaml
    cp fake-service-{{version}}.tgz {{RELEASE_TMP}}/

# Create a Replicated release and promote it to the specified channel
create-release version=VERSION: (prepare-release version)
    replicated release create \
        --yaml-dir {{RELEASE_TMP}} \
        --promote {{CHANNEL}} \
        --version {{version}} \
        --ensure-channel

# Download a license for the specified channel
download-license:
    #!/usr/bin/env bash
    set -euo pipefail
    CUSTOMER_NAME="{{CHANNEL}}-customer"
    replicated customer create --name "${CUSTOMER_NAME}" --channel {{CHANNEL}}
    replicated customer download-license --customer "${CUSTOMER_NAME}" --output license.yaml

# Bump the version and create a new release
bump version=VERSION: (create-release version)

# Reproduce a release: create it and download the license
reproducing version=VERSION: (create-release version) download-license

# Clean up temporary artifacts
clean:
    rm -rf {{RELEASE_TMP}}
    rm -f fake-service-*.tgz
    rm -f license.yaml

# Print the embedded cluster install command
install-guide:
    #!/usr/bin/env bash
    set -euo pipefail
    LICENSE_ID=$(yq '.spec.licenseID' license.yaml)
    echo "curl -f \"https://replicated.app/embedded/{{APP_SLUG}}/{{CHANNEL}}\" -H \"Authorization: ${LICENSE_ID}\" -o {{APP_SLUG}}-{{CHANNEL}}.tgz"

# Print the kots install command
install-kots:
    echo "kubectl kots install {{APP_SLUG}}/{{CHANNEL}} --license-file license.yaml --namespace foo --shared-password 123456"
