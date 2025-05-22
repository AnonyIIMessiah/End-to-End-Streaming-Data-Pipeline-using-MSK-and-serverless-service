
# 1. Create an S3 bucket for delivery
resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "my-firehose-bucket-example"
  force_destroy = true
}

# 2. Create IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose_delivery_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
  })
}

# 3. Attach policy to allow Firehose to access S3
resource "aws_iam_role_policy" "firehose_s3_policy" {
  name = "firehose_s3_policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.firehose_bucket.arn,
          "${aws_s3_bucket.firehose_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# 4. Create Firehose delivery stream (Direct-Put to S3)
# resource "aws_kinesis_firehose_delivery_stream" "direct_put" {
#   name        = "direct-put-firehose"
#   destination = "s3"

#   s3_configuration {
#     role_arn   = aws_iam_role.firehose_role.arn
#     bucket_arn = aws_s3_bucket.firehose_bucket.arn
#     buffering_interval = 60
#     buffering_size     = 5
#     compression_format = "UNCOMPRESSED"
#   }
# }


resource "aws_kinesis_firehose_delivery_stream" "direct-put-firehose" {
  name        = "direct-put-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn

    buffering_size = 2
    buffering_interval = 120
   
}

}