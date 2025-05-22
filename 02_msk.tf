resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.project-01.id
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