.DEFAULT_GOAL:=help
NAMESPACE=default

##@ Development

code-vet: ## Run go vet for this project. More info: https://golang.org/cmd/vet/
	@echo go vet
	go vet $$(go list ./... )

code-fmt: ## Run go fmt for this project
	@echo go fmt
	go fmt $$(go list ./... )

code-dev: ## Run the default dev commands which are the go fmt and vet then execute the $ make code-gen
	@echo Running the common required commands for developments purposes
	- make code-fmt
	- make code-vet
	- make code-gen

code-gen: ## Run the operator-sdk commands to generated code (k8s and openapi)
	@echo Updating the deep copy files with the changes in the API
	operator-sdk generate k8s
	@echo Updating the CRD files with the OpenAPI validations
	operator-sdk generate crds

apply: ## Apply CRDS to current k8s cluster.
	@echo Applying deploy/crds/*_crd.yaml
	kubectl apply -f deploy/crds/*_crd.yaml

run: ## Run operator locally
	@echo Running operator
	export OPERATOR_NAME=application-operator
	operator-sdk run --local --watch-namespace=${NAMESPACE}

##@ Tests

test-e2e: ## Run integration e2e tests with different options.
	@echo ... Running the same e2e tests with different args ...
	@echo ... Running locally ...
	- kubectl create namespace ${NAMESPACE} || true
	- operator-sdk test local ./test/e2e --up-local --namespace=${NAMESPACE}
	@echo ... Running NOT in parallel ...
	- operator-sdk test local ./test/e2e --go-test-flags "-v -parallel=1"
	@echo ... Running in parallel ...
	- operator-sdk test local ./test/e2e --go-test-flags "-v -parallel=2"
	@echo ... Running without options/args ...
	- operator-sdk test local ./test/e2e
	@echo ... Running with the --debug param ...
	- operator-sdk test local ./test/e2e --debug
	@echo ... Running with the --verbose param ...
	- operator-sdk test local ./test/e2e --verbose

.PHONY: help
help: ## Display this help
	@echo -e "Usage:\n  make \033[36m<target>\033[0m"
	@awk 'BEGIN {FS = ":.*##"}; \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)