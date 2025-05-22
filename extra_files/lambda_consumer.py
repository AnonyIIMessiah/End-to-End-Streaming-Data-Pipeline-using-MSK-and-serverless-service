import base64
import boto3
import json
import os


client = boto3.client('firehose')
deliveryStreamName = os.environ['STREAM_NAME']


def lambda_handler(event, context):
	print(event)
	for partition_key in event['records']:
		partition_value=event['records'][partition_key]
		for record_value in partition_value:
			actual_message=json.loads((base64.b64decode(record_value['value'])).decode('utf-8'))
			print(actual_message)
			newImage = (json.dumps(actual_message)+'\n').encode('utf-8')
			print(newImage)
			response = client.put_record(
			DeliveryStreamName=deliveryStreamName,
			Record={
			'Data': newImage
			})
