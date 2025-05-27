resource "aws_sqs_queue" "terraform_queue" {
  name                       = "api_to_lamda_via_sqs"
  visibility_timeout_seconds = 240
}

data "aws_iam_policy_document" "assume_role_api_gateway" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "iam_for_api_gateway" {
  name = "iam_for_api_gateway"

  assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway.json
}

resource "aws_iam_role_policy_attachment" "sqs_access_api_gateway" {
  role       = aws_iam_role.iam_for_api_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}



resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "publish_to_lambda"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /publisher"

  target = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}

resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id              = aws_apigatewayv2_api.api_gateway.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  # integration_uri    = aws_sqs_queue.terraform_queue.arn
  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.terraform_queue.id
    "MessageBody" = "$request.body.MessageBody"
  }
  credentials_arn        = aws_iam_role.iam_for_api_gateway.arn
  payload_format_version = "1.0"
  timeout_milliseconds   = 10000

}

# resource "aws_apigatewayv2_integration" "example" {
#   api_id              = aws_apigatewayv2_api.example.id
#   credentials_arn     = aws_iam_role.example.arn
#   description         = "SQS example"
#   integration_type    = "AWS_PROXY"
#   integration_subtype = "SQS-SendMessage"

#   request_parameters = {
#     "QueueUrl"    = "$request.header.queueUrl"
#     "MessageBody" = "$request.body.message"
#   }
# }

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}


output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.api_gateway.api_endpoint
}