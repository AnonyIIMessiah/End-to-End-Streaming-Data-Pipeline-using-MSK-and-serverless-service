resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.project-01.id
  # Allow Kafka traffic from Lambda
  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  # Allow Kafka traffic from private EC2 (if needed)
  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.private_ec2.id]
  }

  # Allow Zookeeper traffic from Lambda (if needed)
  ingress {
    from_port       = 2181
    to_port         = 2181
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  # Allow internal MSK communication
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "all_traffic_private_ec2" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.sg.id
  source_security_group_id = aws_security_group.private_ec2.id
  depends_on               = [aws_security_group.private_ec2]
}

resource "aws_kms_key" "kms" {
  description = "lambda-project"
}

resource "aws_msk_cluster" "lambda-project" {
  cluster_name           = "lambda-project"
  kafka_version          = "3.2.0"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type = "kafka.t3.small"
    client_subnets = [
      aws_subnet.Private-subnet-1.id,
      aws_subnet.Private-subnet-2.id
    ]
    storage_info {
      ebs_storage_info {
        volume_size = 1
      }
    }
    security_groups = [aws_security_group.sg.id]
  }
  client_authentication {
    unauthenticated = true
  }
  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = false
    }
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
  }
  tags = {
    app = "lambda-project"
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.lambda-project.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.lambda-project.bootstrap_brokers_tls
}

output "bootstrap_brokers" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.lambda-project.bootstrap_brokers
}