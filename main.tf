provider "aws" {
 region = "us-east-1"
}

module "default_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  attributes  = var.attributes
  delimiter   = var.delimiter
  name        = var.name
  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  tags        = var.tags
}

#resource "aws_security_group_rule" "egress" {
 # type              = "egress"
 #from_port         = "0"
  #to_port           = "0"
  #protocol          = "-1"
  #cidr_blocks       = ["0.0.0.0/0"]
  #security_group_id = aws_security_group.default.id
#}

#resource "aws_security_group_rule" "http_ingress" {
  #count             = var.http_enabled ? 1 : 0
  #type              = "ingress"
  #from_port         = var.http_port
  #to_port           = var.http_port
  #protocol          = "tcp"
  #cidr_blocks       = var.http_ingress_cidr_blocks
  #prefix_list_ids   = var.http_ingress_prefix_list_ids
  #security_group_id = aws_security_group.default.id
#}

#resource "aws_security_group_rule" "https_ingress" {
  #count             = var.https_enabled ? 1 : 0
  #type              = "ingress"
  #from_port         = var.https_port
  #to_port           = var.https_port
  #protocol          = "tcp"
  #cidr_blocks       = var.https_ingress_cidr_blocks
  #prefix_list_ids   = var.https_ingress_prefix_list_ids
  #security_group_id = aws_security_group.default.id
#}


resource "aws_lb" "default" {
  name               = module.default_label.id
  tags               = module.default_label.tags
  internal           = var.internal
  load_balancer_type = "application"

  security_groups = [aws_security_group.web_rules.id]

  #security_groups = compact(
    #concat(var.security_group_ids, [aws_security_group.default.id]),
 #)

  subnets                          = [aws_subnet.subnet_public_a.id,aws_subnet.subnet_public_b.id] #var.subnet_ids
  enable_http2                     = var.http2_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled

}

module "default_target_group_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  attributes  = concat(var.attributes, ["default"])
  delimiter   = var.delimiter
  name        = var.name
  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  tags        = var.tags
}

resource "aws_lb_target_group" "default" {
  name                 = var.target_group_name == "" ? module.default_target_group_label.id : var.target_group_name
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = aws_vpc.vpc.id
  target_type          = var.target_group_target_type
  deregistration_delay = var.deregistration_delay

  health_check {
    protocol            = var.target_group_protocol
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
  }

  dynamic "stickiness" {
    for_each = var.stickiness == null ? [] : [var.stickiness]
    content {
      type            = "lb_cookie"
      cookie_duration = stickiness.value.cookie_duration
      enabled         = var.target_group_protocol == "TCP" ? false : stickiness.value.enabled
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    module.default_target_group_label.tags,
    var.target_group_additional_tags
  )
}

resource "aws_lb_target_group" "pennypinchers" {
  name                 = "pennypinchers"
  port                 = var.db_target_group_port 
  protocol             = var.target_group_protocol
  vpc_id               = aws_vpc.vpc.id
  target_type          = var.target_group_target_type
  deregistration_delay = var.deregistration_delay
  
  health_check {
    protocol            = var.target_group_protocol
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
  } 

  dynamic "stickiness" {
    for_each = var.stickiness == null ? [] : [var.stickiness]
    content {
      type            = "lb_cookie"
      cookie_duration = stickiness.value.cookie_duration
      enabled         = var.target_group_protocol == "TCP" ? false : stickiness.value.enabled
    } 
  } 
  
  lifecycle {
    create_before_destroy = true
  } 
  
  tags = merge(
    module.default_target_group_label.tags,
    var.target_group_additional_tags
  ) 
} 

resource "aws_lb_listener" "db_forward" {
  count             = var.http_enabled && var.http_redirect != true ? 1 : 0
  load_balancer_arn = aws_lb.default.arn
  port              = 27017
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.pennypinchers.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "web-1" {
  target_group_arn = aws_lb_target_group.default.arn
  target_id = aws_instance.web-1.private_ip
  port = 80
}

resource "aws_lb_target_group_attachment" "web-2" {
  target_group_arn = aws_lb_target_group.default.arn
  target_id = aws_instance.web-2.private_ip
  port = 80
}

resource "aws_lb_listener" "http_forward" {
  count             = var.http_enabled && var.http_redirect != true ? 1 : 0
  load_balancer_arn = aws_lb.default.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.default.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "http_redirect" {
  count             = var.http_enabled && var.http_redirect == true ? 1 : 0
  load_balancer_arn = aws_lb.default.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.default.arn
    type             = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.default.arn

  port            = var.https_port
  protocol        = "HTTPS"
  ssl_policy      = var.https_ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.default.arn
    type             = "forward"
  }
}

resource "aws_vpc" "vpc" {
 cidr_block = "10.0.0.0/16"
 enable_dns_support  = true
 enable_dns_hostnames = true
 tags = {
  Environment = "production"
 }
}
resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public_a" {
 vpc_id = aws_vpc.vpc.id
 cidr_block = "10.0.1.0/24"
 map_public_ip_on_launch = "true"
 availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet_public_b" {
 vpc_id = aws_vpc.vpc.id
 cidr_block = "10.0.2.0/24"
 map_public_ip_on_launch = "true"
 availability_zone = "us-east-1b"
}

resource "aws_route_table" "rtb_public" {
 vpc_id = aws_vpc.vpc.id
route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }
}

resource "aws_route_table_association" "rta_subnet_public_a" {
 subnet_id   = aws_subnet.subnet_public_a.id
 route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table_association" "rta_subnet_public_b" {
 subnet_id   = aws_subnet.subnet_public_b.id
 route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "web_rules" {
 name = "websg"
  vpc_id=aws_vpc.vpc.id
 egress {
  to_port=0
  protocol=-1
  from_port=0
  cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
  from_port  = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
}
resource "aws_security_group" "ssh_rules" {
 name = "sshsg"
  vpc_id=aws_vpc.vpc.id
 ingress {
  from_port  = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
}


resource "aws_instance" "web-2" {
  ami      = "ami-0a7f1556c36aaf776"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_rules.id,aws_security_group.ssh_rules.id]
  key_name = "deployer-key"
  depends_on=[aws_internet_gateway.igw]
  subnet_id=aws_subnet.subnet_public_a.id
 }


resource "aws_instance" "web-1" {
 ami      = "ami-0a7f1556c36aaf776"
 instance_type = "t2.micro"
 vpc_security_group_ids = [aws_security_group.ssh_rules.id,aws_security_group.web_rules.id]
  key_name = "deployer-key"
  depends_on=[aws_internet_gateway.igw]
  subnet_id=aws_subnet.subnet_public_b.id
}

#resource "aws_s3_bucket" "cts-statebucket" {
    #bucket = "cts-statebucket"
    #acl    = "public-read"
#}

terraform {
  backend "s3" {
    bucket = "cts-statebucket"
    key    = "s3://cts-statebucket/OG/terraform.tfstate"
    region = "us-east-1"
  }
}
