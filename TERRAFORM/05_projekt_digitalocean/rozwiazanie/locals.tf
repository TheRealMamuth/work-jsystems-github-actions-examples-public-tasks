locals {
  name = "${var.name_prefix}-${random_id.suffix.hex}"
}
