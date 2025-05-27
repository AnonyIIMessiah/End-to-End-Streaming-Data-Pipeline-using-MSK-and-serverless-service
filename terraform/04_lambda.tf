
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda to access MSK"
  vpc_id      = aws_vpc.project-01.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# resource "aws_security_group_rule" "lambda_to_msk" {
#   type                     = "ingress"
#   from_port                = 9092
#   to_port                  = 9092
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.sg.id
#   source_security_group_id = aws_security_group.lambda_sg.id
# }


resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}



resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "msk_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaMSKExecutionRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../extra_files/lambda_producer.py"
  output_path = "../extra_files/lambda_producer.zip"
}

resource "aws_lambda_function" "kafka_producer" {
  filename         = "../extra_files/lambda_producer.zip"
  function_name    = "KafkaProducerFunction"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_producer.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size      = 512
  timeout          = 180
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  environment {
    variables = {
      KAFKA_TOPIC_NAME = var.kafka_topic_name # Replace with your actual topic name
      KAFKA_BROKERS    = aws_msk_cluster.lambda-project.bootstrap_brokers
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.Private-subnet-1.id, aws_subnet.Private-subnet-2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  depends_on = [aws_msk_cluster.lambda-project]
}

resource "aws_lambda_permission" "allow_sqs" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kafka_producer.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.terraform_queue.arn
}
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.terraform_queue.arn
  function_name                      = aws_lambda_function.kafka_producer.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 2
  enabled                            = true
}



resource "aws_lambda_layer_version" "lambda_layer" {
  s3_bucket           = aws_s3_bucket.kafka_producer.bucket
  s3_key              = aws_s3_object.object.key
  layer_name          = "kafka_layer"
  compatible_runtimes = ["python3.10"]
}