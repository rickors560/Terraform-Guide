# Examples

End-to-end deployment examples that demonstrate how to compose Terraform resources into complete, production-grade infrastructure stacks on AWS.

## Purpose

Each example is a self-contained Terraform project that:

- Deploys a fully working architecture with no placeholders
- Includes all necessary configuration files (main.tf, variables.tf, outputs.tf, terraform.tfvars.example, Makefile, README.md)
- Can be applied and destroyed independently
- Documents architecture (with Mermaid diagrams), cost estimates, and cleanup instructions

## Examples

| # | Example | Description | Estimated Cost |
|---|---------|-------------|---------------|
| 01 | [hello-world](./01-hello-world/) | Single EC2 with Nginx in a custom VPC | ~$8/month |
| 02 | [static-website](./02-static-website/) | S3 + CloudFront + Route53 + ACM | ~$2/month |
| 03 | [three-tier-app](./03-three-tier-app/) | VPC + ALB + EC2 ASG + RDS PostgreSQL | ~$90/month |
| 04 | [serverless-api](./04-serverless-api/) | API Gateway + Lambda + DynamoDB (CRUD) | ~$6/month |
| 05 | [container-app](./05-container-app/) | ECS Fargate + ALB + ECR + RDS | ~$87/month |
| 06 | [full-eks-deployment](./06-full-eks-deployment/) | Complete EKS with Helm controllers, RDS, Redis, ECR | ~$268/month |
| 07 | [multi-region](./07-multi-region/) | DR with Route53 failover, cross-region RDS replica, S3 replication | ~$139/month |

## Structure

Each example follows this file layout:

```
examples/{name}/
├── main.tf                  # All resource definitions
├── variables.tf             # Input variables with defaults
├── outputs.tf               # Useful outputs for verification
├── terraform.tfvars.example # Sample variable values
├── Makefile                 # init, plan, apply, destroy, clean targets
├── README.md                # Architecture diagram, cost estimate, usage
└── (additional files)       # user_data.sh, Lambda source, IAM policies
```

## Quick Start

```bash
cd examples/01-hello-world
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

make apply       # init + plan + apply
make destroy     # tear down all resources
make clean       # remove local Terraform files
```

## Cost Warning

Examples deploy real AWS resources that incur charges. Always run `make destroy` when you are finished experimenting. Cost estimates are approximate and assume ap-south-1 pricing with minimal traffic.
