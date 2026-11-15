# Keys persist in remote state. No local_file or local_sensitive_file resources.
resource "tls_private_key" "deploy" {
  algorithm = "ED25519"
}

# Pin the server identity before its first SSH connection.
resource "tls_private_key" "host" {
  algorithm = "ED25519"
}
