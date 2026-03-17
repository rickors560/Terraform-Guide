# Provisioners

## Table of Contents

- [What are Provisioners](#what-are-provisioners)
- [When to Use Provisioners](#when-to-use-provisioners)
- [The Connection Block](#the-connection-block)
- [local-exec Provisioner](#local-exec-provisioner)
- [remote-exec Provisioner](#remote-exec-provisioner)
- [file Provisioner](#file-provisioner)
- [null_resource and terraform_data](#null_resource-and-terraform_data)
- [Provisioner Behavior](#provisioner-behavior)
- [Alternatives to Provisioners](#alternatives-to-provisioners)
- [Best Practices](#best-practices)

---

## What are Provisioners

Provisioners execute scripts or commands on a local or remote machine as part of resource creation or destruction. They are Terraform's escape hatch for tasks that cannot be expressed as declarative resources.

**HashiCorp considers provisioners a last resort.** The Terraform documentation explicitly recommends avoiding them when better alternatives exist. Provisioners introduce several problems:

- They break Terraform's declarative model
- Failures can leave resources in a partially configured state
- They are not reflected in `terraform plan` output
- They only run during creation or destruction, not on updates
- They make configurations harder to test and debug

Despite these drawbacks, provisioners remain useful for specific scenarios where no native alternative exists.

---

## When to Use Provisioners

### Legitimate Use Cases

- **Bootstrapping**: Initial configuration of a server before a configuration management tool takes over
- **Running migrations**: Database schema migrations after an RDS instance is created
- **Triggering external systems**: Notifying a CI/CD pipeline or CMDB after infrastructure changes
- **Registering/deregistering**: Adding a server to a load balancer or service discovery system outside of AWS
- **Cleanup tasks**: Deregistering from external systems on resource destruction

### When NOT to Use Provisioners

- **Installing software**: Use AMI baking (Packer), user_data, or cloud-init
- **Configuration management**: Use Ansible, Chef, Puppet, or Salt
- **Passing data to instances**: Use user_data or instance metadata
- **Running scripts on every apply**: Provisioners only run on creation/destruction

---

## The Connection Block

The `connection` block tells Terraform how to connect to a remote machine for `remote-exec` and `file` provisioners.

### SSH Connection

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/deployer")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["echo 'Connected!'"]
  }
}
```

### SSH Connection with Bastion Host

```hcl
resource "aws_instance" "private_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = var.private_subnet_id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/deployer")
    host        = self.private_ip

    bastion_host        = var.bastion_public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file("~/.ssh/bastion")
  }
}
```

### WinRM Connection (Windows)

```hcl
resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows.id
  instance_type = "t3.medium"

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.public_ip
    https    = true
    insecure = true
  }
}
```

### Connection Block Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `type` | `ssh` or `winrm` | `ssh` |
| `user` | User to connect as | `root` |
| `host` | Address to connect to | (required) |
| `private_key` | SSH private key content | |
| `password` | Password for auth | |
| `port` | Port number | 22 (SSH), 5985/5986 (WinRM) |
| `timeout` | Connection timeout | `5m` |
| `agent` | Use SSH agent | `true` |
| `bastion_host` | Bastion/jump host | |
| `bastion_user` | User on bastion | |
| `bastion_private_key` | Key for bastion | |

---

## local-exec Provisioner

Executes a command on the machine running Terraform (not the created resource).

### Basic Usage

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}
```

### Full Configuration

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  provisioner "local-exec" {
    command     = "ansible-playbook -i '${self.public_ip},' playbook.yml"
    working_dir = "${path.module}/ansible"

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      SERVER_IP                 = self.public_ip
    }

    interpreter = ["/bin/bash", "-c"]

    # Run on creation (default) or destruction
    when = create
  }
}
```

### local-exec on Destroy

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  provisioner "local-exec" {
    when    = destroy
    command = "curl -X DELETE https://cmdb.internal/api/servers/${self.id}"
  }
}
```

### Common local-exec Patterns

```hcl
# Update a DNS record via API
provisioner "local-exec" {
  command = <<-EOT
    curl -X POST https://dns.internal/api/records \
      -H "Content-Type: application/json" \
      -d '{"name": "${var.hostname}", "ip": "${self.public_ip}"}'
  EOT
}

# Generate a kubeconfig after EKS cluster creation
resource "aws_eks_cluster" "main" {
  # ...

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${self.name} --region ${var.region}"
  }
}

# Write inventory for Ansible
resource "aws_instance" "web" {
  count = 3
  # ...

  provisioner "local-exec" {
    command = "echo '${self.public_ip} ansible_user=ubuntu' >> inventory.ini"
  }
}
```

---

## remote-exec Provisioner

Executes commands on the created resource over SSH or WinRM.

### Inline Commands

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
    ]
  }
}
```

### Script File

```hcl
provisioner "remote-exec" {
  script = "${path.module}/scripts/setup.sh"
}
```

### Multiple Scripts

```hcl
provisioner "remote-exec" {
  scripts = [
    "${path.module}/scripts/install-deps.sh",
    "${path.module}/scripts/configure-app.sh",
    "${path.module}/scripts/start-services.sh",
  ]
}
```

---

## file Provisioner

Copies files or directories from the machine running Terraform to the created resource.

### Copy a Single File

```hcl
resource "aws_instance" "web" {
  # ...

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/configs/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo systemctl reload nginx",
    ]
  }
}
```

### Copy a Directory

```hcl
provisioner "file" {
  source      = "${path.module}/configs/"       # Trailing slash copies contents
  destination = "/tmp/configs"
}

# Without trailing slash, copies the directory itself
provisioner "file" {
  source      = "${path.module}/configs"        # No trailing slash
  destination = "/tmp"                          # Creates /tmp/configs/
}
```

### Copy Content from a String

```hcl
provisioner "file" {
  content     = templatefile("${path.module}/templates/app.conf.tpl", {
    db_host = aws_db_instance.main.endpoint
    db_name = var.db_name
  })
  destination = "/tmp/app.conf"
}
```

---

## null_resource and terraform_data

### null_resource (Legacy)

`null_resource` is a resource that does nothing but can trigger provisioners:

```hcl
resource "null_resource" "configure_app" {
  # Re-run when these values change
  triggers = {
    instance_id = aws_instance.web.id
    config_hash = filemd5("${path.module}/configs/app.conf")
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.web.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/configs/app.conf"
    destination = "/tmp/app.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/app.conf /etc/app/app.conf",
      "sudo systemctl restart app",
    ]
  }
}
```

### terraform_data (Terraform 1.4+, Preferred)

`terraform_data` replaces `null_resource` without requiring the `null` provider:

```hcl
resource "terraform_data" "configure_app" {
  triggers_replace = [
    aws_instance.web.id,
    filemd5("${path.module}/configs/app.conf"),
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart app",
    ]
  }
}
```

### Triggering Provisioners on Change

The `triggers` (or `triggers_replace` for `terraform_data`) map determines when the resource is replaced and provisioners re-run:

```hcl
resource "terraform_data" "deployment" {
  triggers_replace = [
    var.app_version,          # Re-deploy when version changes
    var.config_hash,          # Re-deploy when config changes
  ]

  provisioner "local-exec" {
    command = "deploy.sh ${var.app_version}"
  }
}
```

---

## Provisioner Behavior

### Creation-Time vs Destruction-Time

```hcl
resource "aws_instance" "web" {
  # ...

  # Runs when the resource is created (default)
  provisioner "local-exec" {
    when    = create
    command = "register-server.sh ${self.id}"
  }

  # Runs when the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "deregister-server.sh ${self.id}"
  }
}
```

### Failure Behavior

By default, if a provisioner fails, the resource is marked as **tainted** and will be destroyed and recreated on the next apply.

```hcl
provisioner "local-exec" {
  command    = "might-fail.sh"
  on_failure = continue    # Ignore failures and continue
  # on_failure = fail      # Default: mark resource as tainted
}
```

### Execution Order

Multiple provisioners on a resource execute in the order they are defined:

```hcl
resource "aws_instance" "web" {
  # ...

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /tmp/setup.sh && /tmp/setup.sh"]
  }

  provisioner "local-exec" {
    command = "echo 'Server ${self.id} configured'"
  }
}
```

---

## Alternatives to Provisioners

### user_data (EC2 Bootstrap Script)

The preferred method for initial server configuration:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
  EOT

  user_data_replace_on_change = true
}
```

### user_data with cloud-init

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
      - docker.io
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
    write_files:
      - path: /etc/nginx/conf.d/app.conf
        content: |
          server {
            listen 80;
            location / {
              proxy_pass http://localhost:8080;
            }
          }
  EOT
}
```

### user_data with templatefile

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    db_endpoint = aws_db_instance.main.endpoint
    db_name     = var.db_name
    app_version = var.app_version
    region      = var.region
  })
}
```

### Packer for AMI Baking

Instead of configuring servers at boot time, pre-bake an AMI with all software installed:

```json
{
  "builders": [{
    "type": "amazon-ebs",
    "source_ami_filter": {
      "filters": {
        "name": "ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"
      },
      "owners": ["099720109477"],
      "most_recent": true
    },
    "instance_type": "t3.micro",
    "ssh_username": "ubuntu",
    "ami_name": "myapp-{{timestamp}}"
  }],
  "provisioners": [{
    "type": "shell",
    "script": "setup.sh"
  }]
}
```

Then reference the AMI in Terraform:

```hcl
data "aws_ami" "myapp" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["myapp-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.myapp.id
  instance_type = "t3.micro"
  # No provisioners needed — AMI comes pre-configured
}
```

### AWS Systems Manager Run Command

For ongoing management without SSH access:

```hcl
resource "aws_ssm_document" "configure" {
  name            = "configure-app"
  document_type   = "Command"
  document_format = "YAML"

  content = <<-EOT
    schemaVersion: '2.2'
    description: Configure application
    mainSteps:
      - action: aws:runShellScript
        name: configure
        inputs:
          runCommand:
            - apt-get update
            - apt-get install -y nginx
  EOT
}
```

---

## Best Practices

### 1. Prefer Declarative Alternatives

Use `user_data`, cloud-init, pre-baked AMIs, or AWS-native resources before reaching for provisioners.

### 2. Keep Provisioners Idempotent

If a provisioner must re-run, it should produce the same result:

```hcl
# Bad: fails on second run
provisioner "remote-exec" {
  inline = ["mkdir /app"]
}

# Good: idempotent
provisioner "remote-exec" {
  inline = ["mkdir -p /app"]
}
```

### 3. Use terraform_data Instead of null_resource

`terraform_data` is built into Terraform and does not require the null provider.

### 4. Handle Failures Gracefully

For non-critical provisioners, use `on_failure = continue`:

```hcl
provisioner "local-exec" {
  command    = "notify-slack.sh 'Deployment complete'"
  on_failure = continue    # Slack notification failure should not block deployment
}
```

### 5. Use Triggers for Re-execution

Define explicit triggers so provisioners re-run when relevant values change.

### 6. Avoid Storing Secrets in Provisioner Commands

Provisioner commands appear in `terraform plan` output and state. Use SSM Parameter Store or Secrets Manager instead of passing secrets through provisioner scripts.

### 7. Set Timeouts

Remote connections can hang. Set appropriate timeouts:

```hcl
connection {
  type    = "ssh"
  timeout = "5m"
  # ...
}
```

---

## Next Steps

- [Functions and Expressions](functions-and-expressions.md) for templatefile and other functions used with provisioners
- [Modules](modules.md) for encapsulating provisioner logic in reusable modules
- [Security Best Practices](../03-terraform-advanced/security-best-practices.md) for secure secret handling
