# Troubleshooting

Common errors encountered when working with Terraform, AWS, and Kubernetes in this project, along with their causes and fixes.

---

## Terraform Init Errors

### 1. Backend initialization required

**Error:**
```
Error: Backend initialization required, please run "terraform init"
```

**Cause:** You are running `terraform plan` or `apply` in a directory that has not been initialized, or the backend configuration has changed since the last init.

**Fix:**
```bash
terraform init
# If backend config changed:
terraform init -reconfigure
```

---

### 2. Failed to get existing workspaces

**Error:**
```
Error: Failed to get existing workspaces: S3 bucket does not exist.
```

**Cause:** The S3 backend bucket has not been created yet, or the bucket name in the backend configuration is incorrect.

**Fix:**
```bash
# Bootstrap the backend first
cd bootstrap/
terraform init
terraform apply

# Then return to your working directory and init
cd ../environments/dev/
terraform init
```

---

### 3. Provider version constraints

**Error:**
```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider hashicorp/aws
```

**Cause:** Network connectivity issue, or the required provider version does not exist. Can also occur behind a corporate proxy.

**Fix:**
```bash
# Check network access
curl -s https://registry.terraform.io/.well-known/terraform.json

# Clear provider cache and retry
rm -rf .terraform/
terraform init

# If behind a proxy, set environment variables
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
```

---

### 4. Terraform version mismatch

**Error:**
```
Error: Unsupported Terraform Core version
This configuration does not support Terraform version 1.5.x. To proceed, either choose another supported version or update this version constraint.
```

**Cause:** The installed Terraform version does not match the `required_version` constraint in the configuration.

**Fix:**
```bash
# Install the required version
tfenv install 1.9.8
tfenv use 1.9.8
terraform version
```

---

## Terraform Plan / Apply Errors

### 5. Access denied / insufficient permissions

**Error:**
```
Error: error creating S3 Bucket: AccessDenied: Access Denied
```

**Cause:** The AWS credentials in use do not have sufficient IAM permissions for the requested action.

**Fix:**
```bash
# Verify your identity
aws sts get-caller-identity

# Check which profile is active
echo $AWS_PROFILE

# Ensure the IAM user/role has the necessary permissions
# For learning, AdministratorAccess is recommended
```

---

### 6. Resource already exists

**Error:**
```
Error: error creating Security Group: InvalidGroup.Duplicate: A security group with the same name already exists in this VPC.
```

**Cause:** A resource with the same identifier already exists in AWS but is not tracked in Terraform state. This happens when resources were created manually or by another Terraform workspace.

**Fix:**
```bash
# Option 1: Import the existing resource into state
terraform import aws_security_group.example sg-0123456789abcdef0

# Option 2: Remove the external resource manually, then re-apply
# Option 3: Use a different name in your configuration
```

---

### 7. Cycle detected in resource dependencies

**Error:**
```
Error: Cycle: aws_security_group.a, aws_security_group.b
```

**Cause:** Two or more resources reference each other in a way that creates a circular dependency (e.g., security group A references B and B references A).

**Fix:**
```hcl
# Break the cycle by using separate security group rule resources
resource "aws_security_group" "a" {
  name   = "sg-a"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "b" {
  name   = "sg-b"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "a_to_b" {
  type                     = "ingress"
  security_group_id        = aws_security_group.a.id
  source_security_group_id = aws_security_group.b.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}
```

---

### 8. Error acquiring the state lock

**Error:**
```
Error: Error acquiring the state lock
ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        12345678-abcd-1234-abcd-123456789012
  Path:      myapp-dev-terraform-state/dev/terraform.tfstate
  Operation: OperationTypeApply
```

**Cause:** Another Terraform process is currently holding the lock, or a previous process crashed without releasing it.

**Fix:**
```bash
# If you are CERTAIN no other process is running:
terraform force-unlock 12345678-abcd-1234-abcd-123456789012

# Verify no one else is running Terraform on this state
```

---

### 9. Invalid count / for_each argument

**Error:**
```
Error: Invalid count argument
The "count" value depends on resource attributes that cannot be determined until apply.
```

**Cause:** The value passed to `count` or `for_each` depends on a resource that has not been created yet (unknown value at plan time).

**Fix:**
```hcl
# Use a data source or variable instead of a computed value
# BAD:
count = length(aws_subnet.private[*].id)

# GOOD:
count = length(var.private_subnet_cidrs)
```

---

### 10. Timeout waiting for resource

**Error:**
```
Error: error waiting for EKS Cluster (myapp-dev-eks) to create: timeout while waiting for state to become 'ACTIVE' (last state: 'CREATING')
```

**Cause:** The resource took longer to create than the default timeout. EKS clusters typically take 10-15 minutes.

**Fix:**
```hcl
resource "aws_eks_cluster" "this" {
  # ... configuration ...

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
```

---

## State Errors

### 11. State file is locked remotely

**Error:**
```
Error: Error locking state: Error acquiring the state lock
```

**Cause:** Same as error 8 — state lock is held by another process.

**Fix:** See error 8. Additionally, check the DynamoDB table directly:
```bash
aws dynamodb scan --table-name myapp-dev-terraform-locks --region ap-south-1
```

---

### 12. State drift detected

**Symptom:** `terraform plan` shows changes to resources you did not modify.

**Cause:** Someone or something modified the resource outside of Terraform (console, CLI, another tool).

**Fix:**
```bash
# Review the drift
terraform plan

# Option 1: Accept the current AWS state as correct
terraform apply -refresh-only

# Option 2: Reapply your Terraform configuration to overwrite the drift
terraform apply
```

---

### 13. Resource not found in state

**Error:**
```
Error: Resource 'aws_instance.web' not found in state
```

**Cause:** The resource was removed from state (e.g., via `terraform state rm`) or was never created.

**Fix:**
```bash
# List all resources in state
terraform state list

# If the resource exists in AWS, import it
terraform import aws_instance.web i-0123456789abcdef0
```

---

## AWS Authentication Errors

### 14. No valid credential sources found

**Error:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
```

**Cause:** Terraform cannot find AWS credentials. Neither environment variables, shared credentials file, nor instance profile are configured.

**Fix:**
```bash
# Option 1: Set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="ap-south-1"

# Option 2: Use a named profile
export AWS_PROFILE=terraform-guide

# Option 3: Configure credentials file
aws configure --profile terraform-guide
```

---

### 15. Expired or invalid token

**Error:**
```
Error: error calling sts:GetCallerIdentity: ExpiredToken: The security token included in the request is expired
```

**Cause:** The AWS session token has expired. This is common when using SSO, assumed roles, or temporary credentials.

**Fix:**
```bash
# Re-authenticate with SSO
aws sso login --profile terraform-guide

# Or refresh temporary credentials
aws sts get-session-token --duration-seconds 3600
```

---

## Networking Errors

### 16. Subnet CIDR conflicts

**Error:**
```
Error: error creating Subnet: InvalidSubnet.Conflict: The CIDR 10.0.1.0/24 conflicts with another subnet.
```

**Cause:** The CIDR block you are trying to assign to a new subnet overlaps with an existing subnet in the same VPC.

**Fix:**
```bash
# List existing subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxx" \
  --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]" --output table

# Adjust your CIDR allocation to avoid overlaps
```

---

### 17. NAT Gateway elastic IP limit

**Error:**
```
Error: error creating EIP: AddressLimitExceeded: The maximum number of addresses has been reached.
```

**Cause:** Your AWS account has hit the default Elastic IP limit (5 per region).

**Fix:**
```bash
# Check current usage
aws ec2 describe-addresses --query "Addresses[*].[PublicIp,AllocationId,AssociationId]" --output table

# Release unused EIPs, or request a limit increase via AWS Support
```

---

## EKS Errors

### 18. kubectl unauthorized

**Error:**
```
error: You must be logged in to the server (Unauthorized)
```

**Cause:** Your kubeconfig is not configured for the EKS cluster, or your AWS credentials do not map to a Kubernetes RBAC identity.

**Fix:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name myapp-dev-eks --region ap-south-1 --profile terraform-guide

# Verify
kubectl cluster-info
kubectl get nodes
```

---

### 19. EKS node group creation fails

**Error:**
```
Error: error creating EKS Node Group: InvalidParameterException: Subnet subnet-xxx is not in the same VPC as the cluster.
```

**Cause:** The subnets specified for the node group belong to a different VPC than the EKS cluster.

**Fix:**
```hcl
# Ensure node group subnets match the cluster VPC
resource "aws_eks_node_group" "workers" {
  subnet_ids = var.private_subnet_ids  # Must be in the same VPC as the cluster
  # ...
}
```

---

### 20. Pod stuck in Pending state

**Symptom:** `kubectl get pods` shows pods in `Pending` status indefinitely.

**Cause:** Insufficient cluster resources (CPU/memory), no nodes available, node selector/affinity mismatch, or PersistentVolumeClaim cannot be bound.

**Fix:**
```bash
# Describe the pod to see the reason
kubectl describe pod <pod-name>

# Common causes and fixes:
# 1. Insufficient resources → Scale up node group or reduce resource requests
# 2. No matching nodes → Check node labels and pod nodeSelector/affinity
# 3. PVC pending → Check StorageClass and EBS CSI driver
# 4. Taint/toleration mismatch → Add tolerations to the pod spec
```

---

## General Tips

- **Always run `terraform plan` before `terraform apply`** to preview changes.
- **Use `TF_LOG=DEBUG terraform plan`** for verbose logging when debugging provider issues.
- **Check AWS CloudTrail** for API-level errors that Terraform surfaces as generic messages.
- **Use `terraform state list`** and `terraform state show <resource>` to inspect current state.
- **Keep Terraform and provider versions pinned** to avoid unexpected behavior from upgrades.
