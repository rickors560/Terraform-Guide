.PHONY: init plan apply destroy clean fmt validate kubeconfig

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

kubeconfig:
	aws eks update-kubeconfig --region $$(terraform output -raw aws_region 2>/dev/null || echo "ap-south-1") --name $$(terraform output -raw cluster_name)
	@echo "Kubeconfig updated. Run 'kubectl get nodes' to verify."
