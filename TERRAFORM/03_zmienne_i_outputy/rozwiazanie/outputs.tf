output "resource_name_prefix" {
  description = "Prefiks wraz z losowym sufiksem używany w nazwach wszystkich zasobów."
  value       = "${var.name_prefix}-${random_id.suffix.hex}"
}
