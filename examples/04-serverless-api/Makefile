.PHONY: init plan apply destroy clean fmt validate test

init:
	terraform init

plan: init
	terraform plan -out=tfplan

apply: plan
	terraform apply tfplan

destroy:
	terraform destroy -auto-approve

clean:
	rm -rf .terraform .terraform.lock.hcl tfplan terraform.tfstate terraform.tfstate.backup .build/

fmt:
	terraform fmt -recursive

validate: init
	terraform validate

test:
	@echo "--- Creating an item ---"
	@curl -s -X POST $$(terraform output -raw dev_invoke_url)/items \
		-H "Content-Type: application/json" \
		-d '{"name": "Test Item", "description": "Created by make test"}' | python3 -m json.tool
	@echo "\n--- Listing items ---"
	@curl -s $$(terraform output -raw dev_invoke_url)/items | python3 -m json.tool
