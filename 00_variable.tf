variable "kafka_topic_name" {
  description = "value of the Kafka topic name"
  type        = string
  default     = "demo_testing2"
}
variable "msk_cluster_name" {
  description = "value of the MSK cluster name"
  type        = string
  default     = "lambda-project"
}

variable "s3_consumer_bucket_name" {
  description = "value of the S3 bucket name for the consumer"
  type        = string
  default     = "my-tf-kafka-producer"
}
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0af9569868786b23a" # Example AMI ID, replace with your own
  
}