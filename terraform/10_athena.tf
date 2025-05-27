resource "aws_s3_bucket" "athena_results" {
  bucket = "tf-athena-results-demo"  
}
resource "aws_athena_workgroup" "athena_workgroup" {
  name = "streaming-workgroup"
  configuration {
    result_configuration {
      output_location = "s3://tf-athena-results/athena-results/"
    }
  }
}

resource "aws_athena_named_query" "sample_query" {
  name      = "query_from_streaming_data"
  database  = aws_glue_catalog_database.demo-db.name
  query     = <<EOF
SELECT * FROM ${aws_glue_catalog_database.demo-db.name}.${aws_s3_bucket.firehose_bucket.bucket} limit 10;
EOF
  workgroup = aws_athena_workgroup.athena_workgroup.name
}
