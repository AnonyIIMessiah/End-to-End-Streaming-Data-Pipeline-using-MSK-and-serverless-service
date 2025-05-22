resource "aws_s3_bucket" "kafka_producer" {
  bucket = "my-tf-kafka-producer"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.kafka_producer.bucket
  key    = "kafka_demo.zip"
  source = "extra_files/kafka_demo.zip"
}

