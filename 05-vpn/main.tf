resource "aws_key_pair" "vpn" {
  key_name   = "vpn"
  public_key = file("~/.ssh/daws-76s.pub")  # Replace with the path to your public key
}

resource "aws_instance" "vpn" {
  ami           = data.aws_ami.ami_info.id  # Replace with the latest vpn Access Server AMI ID for your region
  instance_type = "t3.micro"
  key_name      = aws_key_pair.vpn.key_name

  vpc_security_group_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
  subnet_id = local.public_subnet_id

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-vpn"
    }
  )
}

output "instance_id" {
  description = "The Instance ID of the vpn Access Server"
  value       = aws_instance.vpn.id
}

output "public_ip" {
  description = "Public IP address of the vpn Access Server"
  value       = aws_instance.vpn.public_ip
}

output "admin_url" {
  description = "URL to access the vpn Admin UI"
  value       = "https://${aws_instance.vpn.public_ip}:943/admin"
}

output "client_url" {
  description = "URL to access the vpn Client UI"
  value       = "https://${aws_instance.vpn.public_ip}:943/"
}
