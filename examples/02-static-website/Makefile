.PHONY: init plan apply destroy clean fmt validate invalidate sync

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

invalidate:
	@echo "Invalidating CloudFront cache..."
	aws cloudfront create-invalidation \
		--distribution-id $$(terraform output -raw cloudfront_distribution_id) \
		--paths "/*"

sync:
	@echo "Syncing ./dist to S3..."
	aws s3 sync ./dist s3://$$(terraform output -raw s3_bucket_name) --delete
