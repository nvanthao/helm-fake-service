VERSION ?= 0.0.1
CHANNEL ?= $(shell git rev-parse --abbrev-ref HEAD)
APP_SLUG ?= gerard-helm-fake-service

# reproduce the issue
# make reproducing VERSION=0.0.1 CHANNEL=appen-123
reproducing:
	dagger call create-replicated-release --token=env://REPLICATED_API_TOKEN --version=$(VERSION) --channel=$(CHANNEL)
	dagger call download-license --token=env://REPLICATED_API_TOKEN --channel=$(CHANNEL) export --path=./license.yaml

create-cmx-vm:
	replicated vm create --distribution ubuntu --version 24.04 --instance-type r1.xlarge --disk 100 --name gerard-vm --ttl 8h
	echo "SSH into VM and run:"
	echo "curl -f \"https://replicated.app/embedded/$(APP_SLUG)/$(CHANNEL)\" -H \"Authorization: $$(cat license.yaml | yq .spec.licenseID)\" -o $(APP_SLUG)-$(CHANNEL).tgz"

# bump the version and create a new release
bump:
	dagger call create-replicated-release --token=env://REPLICATED_API_TOKEN --version=$(VERSION) --channel=$(CHANNEL)

download-license:
	dagger call download-license --token=env://REPLICATED_API_TOKEN --channel=$(CHANNEL) export --path=./license.yaml

install-guide:
	echo "curl -f \"https://replicated.app/embedded/$(APP_SLUG)/$(CHANNEL)\" -H \"Authorization: $$(cat license.yaml | yq .spec.licenseID)\" -o $(APP_SLUG)-$(CHANNEL).tgz"

