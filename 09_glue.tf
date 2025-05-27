
data "aws_iam_policy_document" "assume_role_glue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}



resource "aws_iam_role" "iam_for_glue" {
  name               = "glue"
  assume_role_policy = data.aws_iam_policy_document.assume_role_glue.json
}



resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.iam_for_glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_glue" {
  role       = aws_iam_role.iam_for_glue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "athena_full_access_glue" {
  role       = aws_iam_role.iam_for_glue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"

}
resource "aws_iam_role_policy_attachment" "cloudwatch_full_access_glue" {
  role       = aws_iam_role.iam_for_glue.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"

}

resource "aws_glue_catalog_database" "demo-db" {
  name = "demo-db"
}

resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.demo-db.name
  name          = "demo-crawler"
  role          = aws_iam_role.iam_for_glue.name

  s3_target {
    path = "s3://${aws_s3_bucket.firehose_bucket.bucket}"
  }

  schedule = "cron(0 * * * ? *)" # Every hour


  depends_on = [ aws_s3_bucket.firehose_bucket ]
}