APP_DIR=app
APP_NAME=my-app

helm-dep-up:
	cd $(APP_DIR) && helm dep up

helm-dep-list:
	cd $(APP_DIR) && helm dep list

helm-install-dry-run:
	cd $(APP_DIR) && helm install $(APP_NAME) --dry-run --debug .

helm-install:
	cd $(APP_DIR) && helm install $(APP_NAME) --debug --wait .

helm-uninstall:
	cd $(APP_DIR) && helm uninstall $(APP_NAME)