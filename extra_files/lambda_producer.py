import os
from time import sleep
from json import dumps
from kafka import KafkaProducer
import json

# Read topic and brokers from environment
topic_name = os.environ['KAFKA_TOPIC_NAME']
brokers = os.environ['KAFKA_BROKERS'].split(',')

producer = KafkaProducer(
    bootstrap_servers=brokers,
    value_serializer=lambda x: dumps(x).encode('utf-8')
)

def lambda_handler(event, context):
    print(event)
    for i in event['Records']:
        sqs_message = json.loads(i['body'])
        print(sqs_message)
        producer.send(topic_name, value=sqs_message)
    
    producer.flush()
