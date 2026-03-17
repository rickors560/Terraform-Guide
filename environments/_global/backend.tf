terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "env/global/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "myapp-terraform-locks"
    encrypt        = true
  }
}
