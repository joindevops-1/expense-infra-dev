resource "aws_lb" "backend" {
  name               = "${var.project_name}-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.backend_alb_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  enable_deletion_protection = false

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}"
    }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hi, This response is from Backend ALB"
      status_code  = "200"
    }
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"

  zone_name = var.zone_name

  records = [
    {
      name    = "*.app-${var.environment}"
      type    = "A"
      alias   = {
        name    = aws_lb.backend.dns_name
        zone_id = aws_lb.backend.zone_id
      }
    }
  ]
}