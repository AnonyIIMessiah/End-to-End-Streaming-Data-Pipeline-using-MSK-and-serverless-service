
data "aws_iam_policy_document" "assume_role_consumer" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}



resource "aws_iam_role" "iam_for_lambda_consumer" {
  name               = "iam_for_lambda_consumer"
  assume_role_policy = data.aws_iam_policy_document.assume_role_consumer.json
}



resource "aws_iam_role_policy_attachment" "lambda_basic_execution_consumer" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda_consumer.name
}

resource "aws_iam_role_policy_attachment" "vpc_access_consumer" {
  role       = aws_iam_role.iam_for_lambda_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "msk_access_consumer" {
  role       = aws_iam_role.iam_for_lambda_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaMSKExecutionRole"

}

resource "aws_iam_role_policy_attachment" "kinesis_firehose_access" {
  role       = aws_iam_role.iam_for_lambda_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"

}

data "archive_file" "lambda_consumer" {
  type        = "zip"
  source_file = "extra_files/lambda_consumer.py"
  output_path = "extra_files/lambda_consumer.zip"
}

resource "aws_lambda_function" "kafka_consumer" {
  filename         = "extra_files/lambda_consumer.zip"
  function_name    = "KafkaConsumerFunction"
  role             = aws_iam_role.iam_for_lambda_consumer.arn
  handler          = "lambda_consumer.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size      = 512
  timeout          = 240
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  environment {
    variables = {
      STREAM_NAME = var.kafka_topic_name
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.Private-subnet-1.id, aws_subnet.Private-subnet-2.id]
    security_group_ids = [aws_security_group.sg.id]
  }
  depends_on = [aws_kinesis_firehose_delivery_stream.direct-put-firehose]
}

resource "aws_lambda_event_source_mapping" "msk_trigger" {
  event_source_arn                   = aws_msk_cluster.lambda-project.arn
  function_name                      = aws_lambda_function.kafka_consumer.arn
  topics                             = [var.kafka_topic_name]
  starting_position                  = "LATEST"
  batch_size                         = 10
  maximum_batching_window_in_seconds = 4

  depends_on = [aws_msk_cluster.lambda-project]

}