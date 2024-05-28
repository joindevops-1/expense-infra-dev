resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn"
  public_key = file("~/.ssh/daws-76s.pub")  # Replace with the path to your public key
}


resource "aws_instance" "openvpn" {
  ami           = "ami-06e5a963b2dadea6f"  # Replace with the latest OpenVPN Access Server AMI ID for your region
  instance_type = "t3.micro"
  key_name      = aws_key_pair.openvpn.key_name

  vpc_security_group_ids = [data.aws_ssm_parameter.openvpn_sg_id.value]
  subnet_id = local.public_subnet_id

  #user_data = file("openvpn.sh")

  tags = {
    Name = "OpenVPN-Server"
  }
}

output "instance_id" {
  description = "The Instance ID of the OpenVPN Access Server"
  value       = aws_instance.openvpn.id
}

output "public_ip" {
  description = "Public IP address of the OpenVPN Access Server"
  value       = aws_instance.openvpn.public_ip
}

output "admin_url" {
  description = "URL to access the OpenVPN Admin UI"
  value       = "https://${aws_instance.openvpn.public_ip}:943/admin"
}

output "client_url" {
  description = "URL to access the OpenVPN Client UI"
  value       = "https://${aws_instance.openvpn.public_ip}:943/"
}
