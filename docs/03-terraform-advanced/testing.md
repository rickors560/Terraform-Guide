# Testing Terraform Configurations

## Table of Contents

- [Why Test Infrastructure](#why-test-infrastructure)
- [Testing Pyramid](#testing-pyramid)
- [Terraform Test Framework](#terraform-test-framework)
- [Terratest (Go)](#terratest-go)
- [Kitchen-Terraform](#kitchen-terraform)
- [Unit Testing](#unit-testing)
- [Integration Testing](#integration-testing)
- [Contract Testing](#contract-testing)
- [Test Organization](#test-organization)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)

---

## Why Test Infrastructure

Infrastructure code can cause outages, data loss, and security vulnerabilities. Testing provides confidence that:

- Resources are created with correct configurations
- Modules work as documented
- Refactoring does not break existing infrastructure
- Security policies are enforced
- Costs remain within budget
- Changes do not cause unintended destruction

Without tests, the only validation is `terraform plan` review and manual verification after apply. Both are error-prone, especially at scale.

---

## Testing Pyramid

```
         /\
        /  \     End-to-End Tests
       / E2E\    (Full stack, slow, expensive)
      /------\
     /        \   Integration Tests
    /  Integ.  \  (Real resources, moderate speed)
   /------------\
  /              \ Contract Tests
 /   Contract     \ (Interface validation, fast)
/------------------\
/                    \ Unit Tests
/      Unit Tests      \ (No real resources, fastest)
/--------------------------\
```

Each layer provides different guarantees at different costs:

| Level | Speed | Cost | Confidence | Tools |
|-------|-------|------|-----------|-------|
| Unit | Seconds | Free | Low-Medium | `terraform test` (plan mode), `terraform validate` |
| Contract | Seconds | Free | Medium | `terraform test` (plan mode), custom validators |
| Integration | Minutes | $ (real resources) | High | `terraform test` (apply mode), Terratest |
| End-to-End | 10-60 min | $$ | Highest | Terratest, custom scripts |

---

## Terraform Test Framework

Terraform 1.6+ includes a native test framework. Tests are written in `.tftest.hcl` files.

### Basic Test Structure

```
module/
  main.tf
  variables.tf
  outputs.tf
  tests/
    basic.tftest.hcl
    validation.tftest.hcl
    integration.tftest.hcl
```

### Plan-Only Tests (Unit Tests)

Test that plans produce expected results without creating real resources:

```hcl
# tests/basic.tftest.hcl

# Variables for the test
variables {
  bucket_name = "test-bucket-12345"
  environment = "dev"
}

# Test that the plan looks correct
run "verify_bucket_configuration" {
  command = plan    # plan-only, no real resources

  assert {
    condition     = aws_s3_bucket.main.bucket == "test-bucket-12345"
    error_message = "Bucket name should match the variable"
  }

  assert {
    condition     = aws_s3_bucket.main.tags["Environment"] == "dev"
    error_message = "Environment tag should be 'dev'"
  }
}

run "verify_encryption_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.main.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Bucket should use KMS encryption"
  }
}
```

### Apply Tests (Integration Tests)

Tests that create real resources, verify them, and clean up:

```hcl
# tests/integration.tftest.hcl

variables {
  bucket_name = "test-integration-${run.id}"
  environment = "test"
}

run "create_bucket" {
  command = apply    # Creates real resources

  assert {
    condition     = aws_s3_bucket.main.bucket == var.bucket_name
    error_message = "Bucket was not created with the correct name"
  }

  assert {
    condition     = output.bucket_arn != ""
    error_message = "Bucket ARN should not be empty"
  }
}

# Resources are automatically destroyed after all runs complete
```

### Using Test Providers

Override provider configuration for tests:

```hcl
# tests/basic.tftest.hcl

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      TestRun = "terraform-test"
    }
  }
}
```

### Helper Modules in Tests

Create helper modules that set up prerequisites:

```hcl
# tests/setup/main.tf (helper module)
resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "test-vpc" }
}

output "vpc_id" {
  value = aws_vpc.test.id
}
```

```hcl
# tests/with_vpc.tftest.hcl

run "setup_vpc" {
  command = apply
  module {
    source = "./tests/setup"
  }
}

run "create_subnet" {
  command = plan

  variables {
    vpc_id = run.setup_vpc.vpc_id
  }

  assert {
    condition     = aws_subnet.main.vpc_id == run.setup_vpc.vpc_id
    error_message = "Subnet should be in the test VPC"
  }
}
```

### Running Tests

```bash
# Run all tests
terraform test

# Run with verbose output
terraform test -verbose

# Run a specific test file
terraform test -filter=tests/basic.tftest.hcl

# Run tests with variables
terraform test -var="region=us-west-2"
```

---

## Terratest (Go)

Terratest is a Go library for testing infrastructure code. It provides helpers for running Terraform commands, making HTTP requests, SSH connections, and AWS API calls.

### Setup

```bash
mkdir -p test
cd test
go mod init github.com/myorg/infra-tests
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/stretchr/testify/assert
```

### Basic Test

```go
// test/s3_bucket_test.go
package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestS3Bucket(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/s3-bucket",
        Vars: map[string]interface{}{
            "bucket_name": "test-bucket-" + random.UniqueId(),
            "environment": "test",
        },
        EnvVars: map[string]string{
            "AWS_DEFAULT_REGION": "us-east-1",
        },
    })

    // Clean up resources after test
    defer terraform.Destroy(t, terraformOptions)

    // Create resources
    terraform.InitAndApply(t, terraformOptions)

    // Verify outputs
    bucketID := terraform.Output(t, terraformOptions, "bucket_id")
    assert.NotEmpty(t, bucketID)

    bucketArn := terraform.Output(t, terraformOptions, "bucket_arn")
    assert.Contains(t, bucketArn, "arn:aws:s3:::")

    // Verify the bucket exists using AWS API
    aws.AssertS3BucketExists(t, "us-east-1", bucketID)
}
```

### Testing VPC Module

```go
func TestVPCModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_cidr":    "10.0.0.0/16",
            "environment": "test",
            "azs":         []string{"us-east-1a", "us-east-1b"},
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify VPC
    vpcID := terraform.Output(t, terraformOptions, "vpc_id")
    vpc := aws.GetVpcById(t, vpcID, "us-east-1")
    assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)

    // Verify subnets
    privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
    assert.Equal(t, 2, len(privateSubnetIDs))

    publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
    assert.Equal(t, 2, len(publicSubnetIDs))

    // Verify subnets are in different AZs
    for _, subnetID := range privateSubnetIDs {
        subnet := aws.GetSubnet(t, subnetID, "us-east-1")
        assert.Equal(t, vpcID, subnet.VpcId)
    }
}
```

### Testing HTTP Endpoints

```go
func TestWebServer(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/web-server",
        Vars: map[string]interface{}{
            "instance_type": "t3.micro",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    publicIP := terraform.Output(t, terraformOptions, "public_ip")

    // Wait for the server to be ready
    url := fmt.Sprintf("http://%s", publicIP)
    http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello, World!", 30, 10*time.Second)
}
```

### Run Terratest

```bash
cd test
go test -v -timeout 30m
go test -v -timeout 30m -run TestS3Bucket    # run specific test
```

---

## Kitchen-Terraform

Kitchen-Terraform integrates Test Kitchen (Ruby) with Terraform for testing.

### Setup

```ruby
# Gemfile
source "https://rubygems.org"

gem "kitchen-terraform", "~> 7.0"
```

### Configuration

```yaml
# .kitchen.yml
driver:
  name: terraform
  root_module_directory: .
  variable_files:
    - testing.tfvars

provisioner:
  name: terraform

verifier:
  name: terraform
  systems:
    - name: default
      backend: aws
      controls:
        - s3_bucket
        - encryption

platforms:
  - name: aws

suites:
  - name: default
```

### InSpec Controls

```ruby
# test/integration/default/controls/s3_bucket.rb
control "s3_bucket" do
  title "S3 Bucket Configuration"

  bucket_name = attribute("bucket_name")

  describe aws_s3_bucket(bucket_name) do
    it { should exist }
    its("bucket_acl") { should_not include "public" }
  end

  describe aws_s3_bucket(bucket_name) do
    it { should have_default_encryption_enabled }
  end
end
```

---

## Unit Testing

Unit tests verify configuration logic without creating real resources.

### terraform validate

The simplest unit test:

```bash
terraform init -backend=false
terraform validate
```

### Plan-Based Assertions

```hcl
# tests/unit.tftest.hcl

# Test variable validation
run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [
    var.environment,
  ]
}

# Test conditional logic
run "production_uses_large_instances" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_instance.web.instance_type == "t3.large"
    error_message = "Production should use t3.large instances"
  }
}

run "dev_uses_micro_instances" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = aws_instance.web.instance_type == "t3.micro"
    error_message = "Dev should use t3.micro instances"
  }
}
```

### Testing Locals and Functions

```hcl
run "verify_name_prefix" {
  command = plan

  variables {
    project     = "myapp"
    environment = "prod"
  }

  assert {
    condition     = local.name_prefix == "myapp-prod"
    error_message = "Name prefix should be project-environment"
  }
}

run "verify_subnet_calculation" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/16"
  }

  assert {
    condition     = local.public_subnets[0] == "10.0.0.0/24"
    error_message = "First public subnet CIDR is incorrect"
  }
}
```

---

## Integration Testing

Integration tests create real resources and verify their behavior.

### Testing Resource Properties

```hcl
# tests/integration.tftest.hcl

run "create_and_verify_vpc" {
  command = apply

  variables {
    vpc_cidr    = "10.99.0.0/16"
    environment = "test"
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.99.0.0/16"
    error_message = "VPC CIDR block does not match"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled"
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "Should create 3 private subnets"
  }
}
```

### Testing Cross-Resource Dependencies

```go
// Terratest: verify that security group allows traffic
func TestSecurityGroupAllowsHTTPS(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/security-groups",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    sgID := terraform.Output(t, terraformOptions, "web_sg_id")

    // Verify the security group rules
    sg := aws.GetSecurityGroup(t, sgID, "us-east-1")
    assert.True(t, hasIngressRule(sg, 443, "0.0.0.0/0"))
}
```

---

## Contract Testing

Contract tests verify the interface between modules without testing implementation details.

### Module Output Contract

```hcl
# tests/contract.tftest.hcl

run "outputs_have_correct_types" {
  command = plan

  assert {
    condition     = can(output.vpc_id)
    error_message = "Module must output vpc_id"
  }

  assert {
    condition     = can(output.private_subnet_ids)
    error_message = "Module must output private_subnet_ids"
  }

  assert {
    condition     = length(output.private_subnet_ids) > 0
    error_message = "Must create at least one private subnet"
  }
}
```

### Variable Validation as Contracts

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Test the contract
run "rejects_invalid_environment" {
  command = plan
  variables {
    environment = "production"    # Wrong — should be "prod"
  }
  expect_failures = [var.environment]
}
```

---

## Test Organization

### Directory Structure

```
project/
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
      tests/
        unit.tftest.hcl          # Plan-only tests
        integration.tftest.hcl    # Apply tests
        fixtures/                  # Test fixtures
          basic.tfvars
          complete.tfvars
    compute/
      main.tf
      tests/
        unit.tftest.hcl
  test/                           # Terratest (Go) tests
    vpc_test.go
    compute_test.go
    go.mod
    go.sum
```

### Naming Conventions

- Test files: `*.tftest.hcl` (Terraform native) or `*_test.go` (Terratest)
- Test runs: Descriptive names like `verify_encryption_enabled`, `reject_public_access`
- Test variables: Use `testing.tfvars` or inline `variables {}` blocks

### Parallel Testing

For Terratest, use unique resource names to enable parallel execution:

```go
func TestModuleA(t *testing.T) {
    t.Parallel()
    uniqueID := random.UniqueId()
    // Use uniqueID in resource names
}

func TestModuleB(t *testing.T) {
    t.Parallel()
    uniqueID := random.UniqueId()
    // Use uniqueID in resource names
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Terraform Tests
on:
  pull_request:
    paths:
      - "modules/**"
      - "test/**"

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.3"
      - name: Terraform Test
        run: |
          cd modules/vpc
          terraform init
          terraform test

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - name: Integration Tests
        run: |
          cd modules/vpc
          terraform init
          terraform test -filter=tests/integration.tftest.hcl
```

---

## Best Practices

### 1. Test at Multiple Levels

Do not rely on a single type of test. Use plan-based unit tests for fast feedback and integration tests for confidence.

### 2. Clean Up Test Resources

Always use `defer terraform.Destroy()` in Terratest or rely on Terraform test's automatic cleanup. Leaked resources cost money.

### 3. Use Unique Names in Tests

Prevent collisions between parallel test runs by including random IDs in resource names.

### 4. Keep Tests Fast

Plan-only tests run in seconds. Run them on every PR. Reserve integration tests for merge to main or nightly builds.

### 5. Test Failure Cases

Verify that invalid inputs are rejected:

```hcl
run "reject_invalid_cidr" {
  command = plan
  variables {
    vpc_cidr = "not-a-cidr"
  }
  expect_failures = [var.vpc_cidr]
}
```

### 6. Test Destructive Changes

Verify that changing certain attributes triggers replacement:

```hcl
run "region_change_forces_replacement" {
  command = plan
  variables {
    region = "eu-west-1"    # Changed from us-east-1
  }

  assert {
    condition     = aws_instance.web.region == "eu-west-1"
    error_message = "Region should update"
  }
}
```

### 7. Document Test Requirements

Tests that create real resources need AWS credentials and cost money. Document this clearly so contributors know what to expect.

---

## Next Steps

- [Custom Providers](custom-providers.md) for testing custom provider code
- [Modules](../02-terraform-intermediate/modules.md) for the modules being tested
- [Security Best Practices](security-best-practices.md) for security testing with Checkov and OPA
