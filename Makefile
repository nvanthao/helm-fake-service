VERSION ?= 0.0.1
CHANNEL ?= Unstable

# reproduce the issue
# make reproducing VERSION=0.0.1 CHANNEL=appen-123
reproducing:
	dagger call create-replicated-release --token=env://REPLICATED_API_TOKEN --version=$(VERSION) --channel=$(CHANNEL)
	dagger call download-license --token=env://REPLICATED_API_TOKEN --channel=$(CHANNEL) export --path=./license.yaml