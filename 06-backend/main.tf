resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-${var.environment}-backend"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  health_check {
    healthy_threshold   = 2
    interval            = 10
    unhealthy_threshold = 3
    timeout             = 5
    path                = "/health"
    port                = 8080
    matcher = "200-299"
  }
}

module "backend" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.ami_info.id
  name                   = "${var.project_name}-${var.environment}-backend-ami"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]
  subnet_id              = element(split(",", data.aws_ssm_parameter.private_subnet_ids.value), 0)
  #iam_instance_profile = "ShellScriptRoleForRoboshop"
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ami"
    }
  )
}

resource "null_resource" "backend" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.backend.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = module.backend.private_ip
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh backend"
    ]
  }
}

resource "aws_ec2_instance_state" "backend" {
  instance_id = module.backend.id
  state       = "stopped"
  depends_on = [ null_resource.backend ]
}

resource "aws_ami_from_instance" "backend" {
  name               = "${var.project_name}-${var.environment}-backend-${local.current_time}"
  source_instance_id = module.backend.id
  depends_on = [ aws_ec2_instance_state.backend ]
}

resource "null_resource" "backend_delete" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.backend.id
  }

  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = "aws ec2 terminate-instances --instance-ids ${module.backend.id}"
  }

  depends_on = [ aws_ami_from_instance.backend]
}

resource "aws_launch_template" "backend" {
  name = "${var.project_name}-${var.environment}-backend"

  image_id = aws_ami_from_instance.backend.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  update_default_version = true

  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-${var.environment}-backend"
    }
  }

}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project_name}-${var.environment}-backend"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 2
  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  target_group_arns = [ aws_lb_target_group.backend.arn ]
  
  launch_template {
    id      = aws_launch_template.backend.id
    version = aws_launch_template.backend.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-backend"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }


  condition {
    host_header {
      values = ["backend.app-${var.environment}.${var.zone_name}"]
    }
  }
}

resource "aws_autoscaling_policy" "backend" {
  autoscaling_group_name = aws_autoscaling_group.backend.name
  name                   = "${var.project_name}-${var.environment}-backend"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 5.0
  }
}