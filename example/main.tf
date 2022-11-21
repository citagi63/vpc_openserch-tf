
 resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}
resource "aws_elasticsearch_domain" "opensearch" {
  domain_name           = var.domain_name
  elasticsearch_version = var.elasticsearch_version
  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    #zone_awareness_enabled = "true"
    #master_user_name = var.master_user_name
   # master_user_password = var.master_user_password
  }
    ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.volume_size
    volume_type = var.volume_type
  }
  node_to_node_encryption {
    enabled = true
  }
  
  vpc_options {
  subnet_ids = [
     aws_subnet.conductor_private_subnet.id
   ]
   security_group_ids = [aws_security_group.allow_tls.id]

 }
   domain_endpoint_options {
    enforce_https = var.enforce_https
    tls_security_policy = var.tls_security_policy
  }
  advanced_security_options {
    enabled = true
     master_user_options {
      master_user_arn = "arn:aws:iam::375566442973:user/master"
  }
  }
  encrypt_at_rest {
    enabled    = "true"
    kms_key_id = ""
  }
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }
  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:domain/${var.domain_name}"
        }
    ]
}
CONFIG
  depends_on      = [aws_iam_service_linked_role.es]
}
