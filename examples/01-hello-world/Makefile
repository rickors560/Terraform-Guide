.PHONY: init plan apply destroy clean fmt validate

init:
	terraform init

plan: init
	terraform plan -out=tfplan

apply: plan
	terraform apply tfplan

destroy:
	terraform destroy -auto-approve

clean:
	rm -rf .terraform .terraform.lock.hcl tfplan terraform.tfstate terraform.tfstate.backup

fmt:
	terraform fmt -recursive

validate: init
	terraform validate
