TF_DIR := environments/dev

.PHONY: init plan apply destroy fmt validate package-lambda

init:
	terraform -chdir=$(TF_DIR) init

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy

fmt:
	terraform fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) validate

package-lambda:
	./infra-scripts/package_lambda.sh
