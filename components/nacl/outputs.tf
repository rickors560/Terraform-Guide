# -----------------------------------------------------------------------------
# NACL Component - Outputs
# -----------------------------------------------------------------------------

output "public_nacl_id" {
  description = "ID of the public subnet NACL"
  value       = aws_network_acl.public.id
}

output "private_app_nacl_id" {
  description = "ID of the private application subnet NACL"
  value       = aws_network_acl.private_app.id
}

output "private_db_nacl_id" {
  description = "ID of the private database subnet NACL"
  value       = aws_network_acl.private_db.id
}

output "all_nacl_ids" {
  description = "Map of all NACL IDs by tier"
  value = {
    public      = aws_network_acl.public.id
    private_app = aws_network_acl.private_app.id
    private_db  = aws_network_acl.private_db.id
  }
}
