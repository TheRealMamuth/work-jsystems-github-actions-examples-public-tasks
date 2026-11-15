# Terraform init
terraform init -backend-config="conn_str=postgresql://postgres:terraform@localhost:5432/terraform?sslmode=disable"