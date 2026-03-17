# Custom Providers

## Table of Contents

- [When to Build a Custom Provider](#when-to-build-a-custom-provider)
- [Provider Architecture](#provider-architecture)
- [Development Environment Setup](#development-environment-setup)
- [Terraform Plugin Framework](#terraform-plugin-framework)
- [Schema Definition](#schema-definition)
- [CRUD Operations](#crud-operations)
- [Building a Complete Provider](#building-a-complete-provider)
- [Testing Custom Providers](#testing-custom-providers)
- [Publishing to the Registry](#publishing-to-the-registry)
- [Provider Design Best Practices](#provider-design-best-practices)

---

## When to Build a Custom Provider

Build a custom provider when:

- **Internal APIs**: Your organization has proprietary APIs that no existing provider covers
- **Custom platforms**: You maintain an internal PaaS or service catalog
- **Legacy systems**: You need to manage resources in systems without existing providers (mainframes, CMDB systems)
- **Specialized workflows**: You need to integrate Terraform with a niche tool or service
- **Wrapping existing providers**: You want to enforce organization-specific defaults or restrictions

Do NOT build a custom provider when:

- A community provider already exists (even if imperfect — contribute fixes instead)
- The `external` data source or `local-exec` provisioner can handle the use case
- The HTTP provider can interact with the API directly

---

## Provider Architecture

```
+---------------------------+
|     Terraform Core        |
|   (terraform binary)      |
+----------+----------------+
           |
           | gRPC (Protocol Buffers)
           |
+----------v----------------+
|    Provider Plugin         |
|   (separate binary)       |
|                           |
|  +---------------------+  |
|  |   Provider Server    | |
|  +-----+---------------+  |
|        |                   |
|  +-----v---------------+  |
|  |  Resource Schemas    |  |
|  |  Data Source Schemas |  |
|  +-----+---------------+  |
|        |                   |
|  +-----v---------------+  |
|  |  CRUD Handlers       |  |
|  |  (Create/Read/       |  |
|  |   Update/Delete)     |  |
|  +-----+---------------+  |
|        |                   |
+--------+------------------+
         |
         | HTTP/gRPC/SDK
         |
+--------v------------------+
|    External API            |
+---------------------------+
```

### Plugin Frameworks

HashiCorp provides two frameworks for building providers:

| Framework | Status | Language | Recommendation |
|-----------|--------|----------|----------------|
| Terraform Plugin Framework | Current | Go | Use for all new providers |
| Terraform Plugin SDK v2 | Maintenance | Go | Legacy — migrate to Framework |

The **Terraform Plugin Framework** is the recommended approach for all new development.

---

## Development Environment Setup

### Prerequisites

```bash
# Install Go (1.21+)
# macOS
brew install go

# Linux
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Verify
go version
```

### Create the Project

```bash
mkdir terraform-provider-example
cd terraform-provider-example
go mod init github.com/myorg/terraform-provider-example
```

### Install Dependencies

```bash
go get github.com/hashicorp/terraform-plugin-framework
go get github.com/hashicorp/terraform-plugin-go
go get github.com/hashicorp/terraform-plugin-testing
```

### Project Structure

```
terraform-provider-example/
  main.go                          # Entry point
  internal/
    provider/
      provider.go                  # Provider definition
      provider_test.go
    resources/
      server_resource.go           # Resource: example_server
      server_resource_test.go
    datasources/
      server_data_source.go        # Data source: example_server
      server_data_source_test.go
    client/
      client.go                    # API client
  examples/
    main.tf                        # Example usage
  docs/                            # Auto-generated documentation
  go.mod
  go.sum
  .goreleaser.yml                  # Release configuration
```

### Development Override

Configure Terraform to use your local provider binary during development:

```hcl
# ~/.terraformrc (or %APPDATA%/terraform.rc on Windows)
provider_installation {
  dev_overrides {
    "myorg/example" = "/home/user/go/bin"
  }

  direct {}
}
```

---

## Terraform Plugin Framework

### Main Entry Point

```go
// main.go
package main

import (
    "context"
    "log"

    "github.com/hashicorp/terraform-plugin-framework/providerserver"
    "github.com/myorg/terraform-provider-example/internal/provider"
)

func main() {
    opts := providerserver.ServeOpts{
        Address: "registry.terraform.io/myorg/example",
    }

    err := providerserver.Serve(context.Background(), provider.New, opts)
    if err != nil {
        log.Fatal(err.Error())
    }
}
```

### Provider Definition

```go
// internal/provider/provider.go
package provider

import (
    "context"

    "github.com/hashicorp/terraform-plugin-framework/datasource"
    "github.com/hashicorp/terraform-plugin-framework/provider"
    "github.com/hashicorp/terraform-plugin-framework/provider/schema"
    "github.com/hashicorp/terraform-plugin-framework/resource"
    "github.com/hashicorp/terraform-plugin-framework/types"
    "github.com/myorg/terraform-provider-example/internal/client"
)

type exampleProvider struct {
    version string
    client  *client.Client
}

type exampleProviderModel struct {
    Endpoint types.String `tfsdk:"endpoint"`
    ApiKey   types.String `tfsdk:"api_key"`
}

func New(version string) func() provider.Provider {
    return func() provider.Provider {
        return &exampleProvider{
            version: version,
        }
    }
}

func (p *exampleProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
    resp.TypeName = "example"
    resp.Version = p.version
}

func (p *exampleProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "Interact with the Example API.",
        Attributes: map[string]schema.Attribute{
            "endpoint": schema.StringAttribute{
                Description: "API endpoint URL. Can also be set with EXAMPLE_ENDPOINT env var.",
                Optional:    true,
            },
            "api_key": schema.StringAttribute{
                Description: "API key for authentication. Can also be set with EXAMPLE_API_KEY env var.",
                Optional:    true,
                Sensitive:   true,
            },
        },
    }
}

func (p *exampleProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
    var config exampleProviderModel
    diags := req.Config.Get(ctx, &config)
    resp.Diagnostics.Append(diags...)
    if resp.Diagnostics.HasError() {
        return
    }

    endpoint := config.Endpoint.ValueString()
    apiKey := config.ApiKey.ValueString()

    // Fall back to environment variables
    if endpoint == "" {
        endpoint = os.Getenv("EXAMPLE_ENDPOINT")
    }
    if apiKey == "" {
        apiKey = os.Getenv("EXAMPLE_API_KEY")
    }

    if endpoint == "" {
        resp.Diagnostics.AddError(
            "Missing API Endpoint",
            "Set the endpoint in the provider configuration or EXAMPLE_ENDPOINT environment variable.",
        )
        return
    }

    c, err := client.NewClient(endpoint, apiKey)
    if err != nil {
        resp.Diagnostics.AddError("Unable to create API client", err.Error())
        return
    }

    p.client = c
    resp.DataSourceData = c
    resp.ResourceData = c
}

func (p *exampleProvider) Resources(_ context.Context) []func() resource.Resource {
    return []func() resource.Resource{
        resources.NewServerResource,
    }
}

func (p *exampleProvider) DataSources(_ context.Context) []func() datasource.DataSource {
    return []func() datasource.DataSource{
        datasources.NewServerDataSource,
    }
}
```

---

## Schema Definition

### Resource Schema

```go
// internal/resources/server_resource.go
func (r *serverResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "Manages a server.",
        Attributes: map[string]schema.Attribute{
            "id": schema.StringAttribute{
                Description: "Unique identifier of the server.",
                Computed:    true,
                PlanModifiers: []planmodifier.String{
                    stringplanmodifier.UseStateForUnknown(),
                },
            },
            "name": schema.StringAttribute{
                Description: "Name of the server.",
                Required:    true,
            },
            "size": schema.StringAttribute{
                Description: "Server size (small, medium, large).",
                Required:    true,
                Validators: []validator.String{
                    stringvalidator.OneOf("small", "medium", "large"),
                },
            },
            "region": schema.StringAttribute{
                Description: "Region where the server is deployed.",
                Required:    true,
                PlanModifiers: []planmodifier.String{
                    stringplanmodifier.RequiresReplace(),
                },
            },
            "ip_address": schema.StringAttribute{
                Description: "Public IP address of the server.",
                Computed:    true,
            },
            "tags": schema.MapAttribute{
                Description: "Tags to apply to the server.",
                Optional:    true,
                ElementType: types.StringType,
            },
            "last_updated": schema.StringAttribute{
                Description: "Timestamp of last update.",
                Computed:    true,
            },
        },
    }
}
```

### Attribute Properties

| Property | Description |
|----------|-------------|
| `Required` | Must be specified in config |
| `Optional` | Can be omitted (may have a default) |
| `Computed` | Set by the provider, not the user |
| `Sensitive` | Redacted from logs and output |
| `PlanModifiers` | Custom plan-time behavior |
| `Validators` | Custom validation logic |

### Plan Modifiers

```go
// RequiresReplace: changing this attribute destroys and recreates
stringplanmodifier.RequiresReplace()

// UseStateForUnknown: keep the old value during plan (for computed attrs)
stringplanmodifier.UseStateForUnknown()

// RequiresReplaceIfConfigured: only force replace if user sets value
stringplanmodifier.RequiresReplaceIfConfigured()
```

---

## CRUD Operations

### Resource Model

```go
type serverResourceModel struct {
    ID          types.String `tfsdk:"id"`
    Name        types.String `tfsdk:"name"`
    Size        types.String `tfsdk:"size"`
    Region      types.String `tfsdk:"region"`
    IPAddress   types.String `tfsdk:"ip_address"`
    Tags        types.Map    `tfsdk:"tags"`
    LastUpdated types.String `tfsdk:"last_updated"`
}
```

### Create

```go
func (r *serverResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
    var plan serverResourceModel
    diags := req.Plan.Get(ctx, &plan)
    resp.Diagnostics.Append(diags...)
    if resp.Diagnostics.HasError() {
        return
    }

    // Call the API
    server, err := r.client.CreateServer(client.CreateServerRequest{
        Name:   plan.Name.ValueString(),
        Size:   plan.Size.ValueString(),
        Region: plan.Region.ValueString(),
    })
    if err != nil {
        resp.Diagnostics.AddError("Error creating server", err.Error())
        return
    }

    // Map API response to state
    plan.ID = types.StringValue(server.ID)
    plan.IPAddress = types.StringValue(server.IPAddress)
    plan.LastUpdated = types.StringValue(time.Now().Format(time.RFC3339))

    diags = resp.State.Set(ctx, plan)
    resp.Diagnostics.Append(diags...)
}
```

### Read

```go
func (r *serverResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
    var state serverResourceModel
    diags := req.State.Get(ctx, &state)
    resp.Diagnostics.Append(diags...)
    if resp.Diagnostics.HasError() {
        return
    }

    server, err := r.client.GetServer(state.ID.ValueString())
    if err != nil {
        // If the resource no longer exists, remove it from state
        resp.State.RemoveResource(ctx)
        return
    }

    state.Name = types.StringValue(server.Name)
    state.Size = types.StringValue(server.Size)
    state.Region = types.StringValue(server.Region)
    state.IPAddress = types.StringValue(server.IPAddress)

    diags = resp.State.Set(ctx, &state)
    resp.Diagnostics.Append(diags...)
}
```

### Update

```go
func (r *serverResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
    var plan serverResourceModel
    diags := req.Plan.Get(ctx, &plan)
    resp.Diagnostics.Append(diags...)
    if resp.Diagnostics.HasError() {
        return
    }

    server, err := r.client.UpdateServer(plan.ID.ValueString(), client.UpdateServerRequest{
        Name: plan.Name.ValueString(),
        Size: plan.Size.ValueString(),
    })
    if err != nil {
        resp.Diagnostics.AddError("Error updating server", err.Error())
        return
    }

    plan.IPAddress = types.StringValue(server.IPAddress)
    plan.LastUpdated = types.StringValue(time.Now().Format(time.RFC3339))

    diags = resp.State.Set(ctx, plan)
    resp.Diagnostics.Append(diags...)
}
```

### Delete

```go
func (r *serverResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
    var state serverResourceModel
    diags := req.State.Get(ctx, &state)
    resp.Diagnostics.Append(diags...)
    if resp.Diagnostics.HasError() {
        return
    }

    err := r.client.DeleteServer(state.ID.ValueString())
    if err != nil {
        resp.Diagnostics.AddError("Error deleting server", err.Error())
        return
    }
    // State is automatically removed when Delete returns without error
}
```

### ImportState

```go
func (r *serverResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
    resource.ImportStatePassthroughID(ctx, path.Root("id"), req, resp)
}
```

---

## Building a Complete Provider

### API Client

```go
// internal/client/client.go
package client

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
)

type Client struct {
    endpoint   string
    apiKey     string
    httpClient *http.Client
}

type Server struct {
    ID        string `json:"id"`
    Name      string `json:"name"`
    Size      string `json:"size"`
    Region    string `json:"region"`
    IPAddress string `json:"ip_address"`
}

func NewClient(endpoint, apiKey string) (*Client, error) {
    return &Client{
        endpoint:   endpoint,
        apiKey:     apiKey,
        httpClient: &http.Client{},
    }, nil
}

func (c *Client) CreateServer(req CreateServerRequest) (*Server, error) {
    body, _ := json.Marshal(req)
    httpReq, _ := http.NewRequest("POST", fmt.Sprintf("%s/servers", c.endpoint), bytes.NewBuffer(body))
    httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)
    httpReq.Header.Set("Content-Type", "application/json")

    httpResp, err := c.httpClient.Do(httpReq)
    if err != nil {
        return nil, err
    }
    defer httpResp.Body.Close()

    var server Server
    json.NewDecoder(httpResp.Body).Decode(&server)
    return &server, nil
}
```

### Build and Install

```bash
# Build the provider
go build -o terraform-provider-example

# Install for local development
go install

# With dev_overrides in ~/.terraformrc, skip terraform init
terraform plan
```

---

## Testing Custom Providers

### Acceptance Tests

```go
// internal/resources/server_resource_test.go
package resources_test

import (
    "testing"

    "github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

func TestAccServerResource_basic(t *testing.T) {
    resource.Test(t, resource.TestCase{
        ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
        Steps: []resource.TestStep{
            // Create and Read
            {
                Config: `
                    resource "example_server" "test" {
                        name   = "test-server"
                        size   = "small"
                        region = "us-east-1"
                    }
                `,
                Check: resource.ComposeAggregateTestCheckFunc(
                    resource.TestCheckResourceAttr("example_server.test", "name", "test-server"),
                    resource.TestCheckResourceAttr("example_server.test", "size", "small"),
                    resource.TestCheckResourceAttrSet("example_server.test", "id"),
                    resource.TestCheckResourceAttrSet("example_server.test", "ip_address"),
                ),
            },
            // ImportState
            {
                ResourceName:      "example_server.test",
                ImportState:       true,
                ImportStateVerify: true,
            },
            // Update
            {
                Config: `
                    resource "example_server" "test" {
                        name   = "updated-server"
                        size   = "medium"
                        region = "us-east-1"
                    }
                `,
                Check: resource.ComposeAggregateTestCheckFunc(
                    resource.TestCheckResourceAttr("example_server.test", "name", "updated-server"),
                    resource.TestCheckResourceAttr("example_server.test", "size", "medium"),
                ),
            },
            // Delete is automatic at test end
        },
    })
}
```

### Run Tests

```bash
# Unit tests
go test ./...

# Acceptance tests (hit real APIs)
TF_ACC=1 go test ./internal/resources/ -v -timeout 30m
```

---

## Publishing to the Registry

### Requirements

1. Repository named `terraform-provider-<NAME>` on GitHub
2. GoReleaser configuration for multi-platform builds
3. GPG signing key registered with the Terraform Registry
4. GitHub Actions workflow for automated releases

### GoReleaser Configuration

```yaml
# .goreleaser.yml
builds:
  - env:
      - CGO_ENABLED=0
    mod_timestamp: "{{ .CommitTimestamp }}"
    flags:
      - -trimpath
    ldflags:
      - "-s -w -X main.version={{.Version}}"
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64
    binary: "{{ .ProjectName }}_v{{ .Version }}"

archives:
  - format: zip
    name_template: "{{ .ProjectName }}_{{ .Version }}_{{ .Os }}_{{ .Arch }}"

signs:
  - artifacts: checksum
    args:
      - "--batch"
      - "--local-user"
      - "{{ .Env.GPG_FINGERPRINT }}"
      - "--output"
      - "${signature}"
      - "--detach-sign"
      - "${artifact}"

release:
  draft: false

changelog:
  sort: asc
```

### GitHub Actions Release Workflow

```yaml
name: Release
on:
  push:
    tags:
      - "v*"

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.21"
      - name: Import GPG key
        uses: crazy-max/ghaction-import-gpg@v6
        with:
          gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
          passphrase: ${{ secrets.GPG_PASSPHRASE }}
      - name: GoReleaser
        uses: goreleaser/goreleaser-action@v5
        with:
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GPG_FINGERPRINT: ${{ steps.import_gpg.outputs.fingerprint }}
```

---

## Provider Design Best Practices

### 1. Follow Terraform Provider Design Principles

- Resources should map to real API objects
- Attribute names should match the API naming conventions
- Computed attributes should be used for server-generated values
- Use `RequiresReplace` for attributes that cannot be updated in place

### 2. Handle Drift Detection

The Read function should always fetch the latest state from the API. If a resource is deleted externally, remove it from state.

### 3. Implement Import

Every resource should support `terraform import`. This allows users to bring existing resources under Terraform management.

### 4. Support Environment Variables for Auth

Never require credentials in the provider block. Always support environment variables as a fallback.

### 5. Add Meaningful Error Messages

```go
resp.Diagnostics.AddError(
    "Unable to Create Server",
    fmt.Sprintf("API returned status %d: %s. Verify your API key has write permissions.", statusCode, body),
)
```

### 6. Use Plan Modifiers for Better Plans

Plan modifiers give users better information during `terraform plan` by indicating which attributes will be known after apply and which changes force replacement.

### 7. Validate Early

Use schema validators to catch invalid input during planning rather than during apply.

---

## Next Steps

- [Testing](testing.md) for comprehensive testing strategies
- [Publishing Modules](../02-terraform-intermediate/modules.md#publishing-modules) for sharing modules
- [Providers](../01-terraform-basics/providers.md) for using providers
