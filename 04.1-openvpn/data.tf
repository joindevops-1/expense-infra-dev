data "aws_ssm_parameter" "openvpn_sg_id" {
  name = "/${var.project_name}/${var.environment}/openvpn_sg_id"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/public_subnet_ids"
}