# Glossary

Terraform, AWS, and Kubernetes terms used throughout this repository.

---

**ACM (AWS Certificate Manager)** — AWS service that provisions, manages, and deploys TLS/SSL certificates for use with AWS services and internal connected resources.

**ALB (Application Load Balancer)** — Layer 7 load balancer that routes HTTP/HTTPS traffic based on content of the request (host headers, path, query strings).

**AMI (Amazon Machine Image)** — A pre-configured virtual machine image used to launch EC2 instances. Contains the OS, application server, and applications.

**Apply** — The Terraform command (`terraform apply`) that executes the planned changes against real infrastructure, creating, modifying, or destroying resources.

**ARN (Amazon Resource Name)** — A unique identifier for AWS resources, formatted as `arn:aws:service:region:account-id:resource-type/resource-id`.

**Auto Scaling Group (ASG)** — AWS feature that automatically adjusts the number of EC2 instances based on demand, health checks, or schedules.

**Availability Zone (AZ)** — An isolated data center within an AWS region. Each region has multiple AZs for high availability.

**Backend** — In Terraform, the mechanism for storing state files. Common backends include local files, S3+DynamoDB, and Terraform Cloud.

**Bastion Host** — A hardened server in a public subnet that provides secure SSH access to resources in private subnets.

**CIDR (Classless Inter-Domain Routing)** — A notation for defining IP address ranges (e.g., `10.0.0.0/16` represents 65,536 addresses).

**CloudFront** — AWS global Content Delivery Network (CDN) that caches content at edge locations for low-latency delivery.

**CloudTrail** — AWS service that records API calls and events across your AWS account for auditing and governance.

**CloudWatch** — AWS monitoring and observability service that collects metrics, logs, and events from AWS resources and applications.

**ConfigMap** — A Kubernetes object that stores non-sensitive configuration data as key-value pairs, injected into pods as environment variables or mounted files.

**CoreDNS** — The default DNS server for Kubernetes clusters, providing service discovery by resolving service names to cluster IP addresses.

**Data Source** — In Terraform, a read-only reference to an existing resource or piece of information not managed by the current configuration.

**Deployment** — A Kubernetes controller that manages a set of identical pods, handling rolling updates and rollbacks.

**Destroy** — The Terraform command (`terraform destroy`) that tears down all resources managed by the current configuration.

**DynamoDB** — AWS fully managed NoSQL key-value database. Used in this project as a Terraform state lock table.

**EBS (Elastic Block Store)** — AWS block storage volumes that attach to EC2 instances. Persistent across instance stops and starts.

**ECR (Elastic Container Registry)** — AWS managed Docker container registry for storing, managing, and deploying container images.

**EFS (Elastic File System)** — AWS fully managed, scalable NFS file system for use with EC2 and EKS.

**EKS (Elastic Kubernetes Service)** — AWS managed Kubernetes control plane service that runs and scales Kubernetes clusters.

**ElastiCache** — AWS managed in-memory caching service supporting Redis and Memcached engines.

**Fargate** — AWS serverless compute engine for ECS and EKS that runs containers without managing underlying EC2 instances.

**Grafana** — Open-source analytics and monitoring platform that creates dashboards from data sources like Prometheus and CloudWatch.

**Helm** — A package manager for Kubernetes that uses charts (templated manifests) to deploy applications.

**HCL (HashiCorp Configuration Language)** — The declarative language used to write Terraform configuration files (`.tf`).

**HPA (Horizontal Pod Autoscaler)** — A Kubernetes controller that automatically scales the number of pod replicas based on CPU, memory, or custom metrics.

**IAM (Identity and Access Management)** — AWS service that controls who (authentication) can do what (authorization) on which resources.

**Idempotent** — A property where applying the same operation multiple times produces the same result. Terraform operations are idempotent — running apply with no changes produces no changes.

**Ingress** — A Kubernetes resource that manages external HTTP/HTTPS access to services inside the cluster, typically via an ALB or NGINX controller.

**Init** — The Terraform command (`terraform init`) that initializes a working directory by downloading providers, modules, and configuring the backend.

**IRSA (IAM Roles for Service Accounts)** — An EKS feature that associates IAM roles with Kubernetes service accounts, enabling fine-grained AWS permissions for pods.

**KMS (Key Management Service)** — AWS service for creating, managing, and auditing encryption keys used to encrypt data at rest.

**Kustomize** — A Kubernetes-native configuration management tool that uses overlays to customize base manifests without templating.

**Lifecycle Rule** — In Terraform, a `lifecycle` block that controls resource behavior (e.g., `prevent_destroy`, `create_before_destroy`, `ignore_changes`). In S3, a rule that automatically transitions or expires objects.

**Locals** — In Terraform, named values computed within a module using the `locals` block. Useful for reducing repetition and computing derived values.

**Module** — In Terraform, a reusable, self-contained package of `.tf` files that encapsulates a set of resources behind a clean input/output interface.

**Multi-AZ** — An AWS deployment pattern where resources are replicated across multiple Availability Zones for high availability.

**NACL (Network Access Control List)** — A stateless firewall at the subnet level in a VPC. Evaluates rules in order for inbound and outbound traffic.

**NAT Gateway** — An AWS-managed service that allows instances in private subnets to initiate outbound internet connections while blocking inbound connections.

**Node Group** — In EKS, a group of EC2 instances (worker nodes) that run Kubernetes pods. Can be managed (AWS-managed) or self-managed.

**OIDC (OpenID Connect)** — An identity layer on top of OAuth 2.0 used by EKS for IRSA and by GitHub Actions for keyless AWS authentication.

**Output** — In Terraform, a declared value that is exported from a module or root configuration, making it available to other configurations or the CLI.

**PDB (Pod Disruption Budget)** — A Kubernetes policy that limits the number of pods that can be voluntarily disrupted at the same time (e.g., during node drains).

**Plan** — The Terraform command (`terraform plan`) that previews the changes Terraform will make without actually applying them.

**Pod** — The smallest deployable unit in Kubernetes — one or more containers that share network and storage, scheduled onto a node.

**Provider** — In Terraform, a plugin that interacts with a specific API (e.g., `hashicorp/aws` for AWS resources).

**Prometheus** — Open-source monitoring system that collects time-series metrics from instrumented targets via a pull model.

**RDS (Relational Database Service)** — AWS managed relational database service supporting PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server.

**Read Replica** — A read-only copy of an RDS database that replicates asynchronously from the primary instance for read scaling.

**Resource** — In Terraform, a block that declares a piece of infrastructure to be created, updated, or destroyed (e.g., `resource "aws_instance" "web"`).

**Route 53** — AWS scalable DNS web service for domain registration, DNS routing, and health checking.

**Route Table** — A VPC component that contains rules (routes) determining where network traffic is directed.

**S3 (Simple Storage Service)** — AWS object storage service offering durability, availability, and scalability for any amount of data.

**Secret** — A Kubernetes object that stores sensitive data (passwords, tokens, keys) encoded in base64, injected into pods.

**Secrets Manager** — AWS service for storing, rotating, and retrieving secrets (database passwords, API keys) programmatically.

**Security Group** — A stateful virtual firewall at the ENI (network interface) level that controls inbound and outbound traffic for AWS resources.

**Service** — A Kubernetes abstraction that defines a stable network endpoint for a set of pods, providing load balancing and service discovery.

**State** — In Terraform, a JSON file (local or remote) that maps configuration resources to real-world infrastructure. The source of truth for what Terraform manages.

**State Lock** — A mechanism (e.g., DynamoDB) that prevents concurrent Terraform operations from corrupting state by allowing only one writer at a time.

**Subnet** — A logical subdivision of a VPC IP address range. Subnets are bound to a single Availability Zone.

**Taint** — In Terraform, marking a resource for forced recreation on the next apply. In Kubernetes, a node attribute that repels pods unless they tolerate it.

**Terraform Cloud** — HashiCorp's managed service for remote state storage, plan/apply execution, and team collaboration on Terraform configurations.

**TFLint** — A pluggable Terraform linter that catches errors, enforces best practices, and validates provider-specific rules.

**Variable** — In Terraform, an input parameter declared with `variable` blocks. Supports types, defaults, descriptions, and validation rules.

**VPC (Virtual Private Cloud)** — An isolated virtual network within AWS where you launch resources. Defined by a CIDR block and composed of subnets, route tables, and gateways.

**VPC Endpoint** — A private connection between a VPC and an AWS service (e.g., S3, DynamoDB) that does not traverse the public internet.

**VPC Peering** — A networking connection between two VPCs that enables traffic routing between them using private IP addresses.

**WAF (Web Application Firewall)** — AWS service that protects web applications from common exploits (SQL injection, XSS) by filtering HTTP/HTTPS requests.

**Workspace** — In Terraform, an isolated state instance within a single backend. Used to manage multiple environments (dev, staging, prod) from the same configuration.
