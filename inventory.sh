terraform state show aws_instance.web-1 | grep public_ip | grep -v associate | awk -F\" '{print $2}' >> ansible-apache/hosts
terraform state show aws_instance.web-2 | grep public_ip | grep -v associate | awk -F\" '{print $2}' >> ansible-apache/hosts
