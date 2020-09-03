resource "aws_route53_zone" "main" {
  name = "considerthesource.io"
}

resource "aws_route53_record" "AWS-Basic-infra-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "AWS-Basic-infra-ns.considerthesource.io"
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.main.name_servers
}

resource "aws_route53_record" "AWS-Basic-infra" {
  name = "AWS-Basic-infra.considerthesource.io"
  zone_id = aws_route53_zone.main.zone_id
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.default.dns_name]
 
}
resource "aws_route53_record" "MongoDB" {
  name = "MongoDB.eureka.considerthesource.io"
  zone_id = aws_route53_zone.main.zone_id
  type    = "A"
  ttl     = "60"
  records = [aws_instance.mongodb_one.public_ip]
  #records = aws_route53_record.MongoDB.records
}

  
