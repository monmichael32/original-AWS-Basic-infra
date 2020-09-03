resource "aws_instance" "mongodb_one" {
    
    tags = {
        Name = "pd-mongodb-one"
    }
    
    ami = "ami-326a5325"
    
    instance_type = "t2.micro"
    
    root_block_device {
        volume_type = "gp2"
        volume_size = "100"
    }
    
    vpc_security_group_ids = [aws_security_group.mongodb.id]
    associate_public_ip_address = true
    key_name = "deployer-key"
    subnet_id=aws_subnet.subnet_public_a.id
}

resource "aws_security_group" "mongodb" {
  name        = "mongodb"
  description = "Security group for mongodb"
 
  vpc_id=aws_vpc.vpc.id

  tags = {
    Name = "mongodb-prod"
  }
}

resource "aws_security_group_rule" "mongodb_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "mongodb_ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "mongodb_mongodb" {
  type            = "ingress"
  from_port       = 27017
  to_port         = 27017
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "mongodb_mongodb_replication" {
  type            = "ingress"
  from_port       = 27019
  to_port         = 27019
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mongodb.id
}
resource "aws_s3_bucket" "cts-web-resources" {
    bucket = "cts-web-resources"
    acl    = "public-read"
    #policy = file("policy.json") 
    
    website {
       index_document = "index.html"
       error_document = "error.html"
}
}

resource "aws_lb_target_group_attachment" "mongodb_one" {
  target_group_arn = aws_lb_target_group.pennypinchers.arn
  target_id = aws_instance.mongodb_one.private_ip
  port = 27017
}

#data "terraform_remote_state" "network" {
  #backend = "s3"
  #config = {
    #bucket = "cts-web-resources"
    #key    = "anaible-apache/files/eureka.tar"
    #region = "us-east-1"
  #}
#}

#terraform {
  #backend "consul" {
    #bucket = "cts-web-resources"
    #key    = "eureka.tar"
    #region = "us-east-1"
  #}
#}
