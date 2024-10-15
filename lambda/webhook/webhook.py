from datetime import datetime

import boto3, os, json

def lambda_handler(event, context):
    now = datetime.now()
    s3 = boto3.client('s3')
    s3.put_object(
        Body=event["body"], 
        Bucket=os.environ['BUCKET_NAME'], 
        Key=now.strftime("%d%m%Y_%H%M%S")+ '.' + json.loads(event["body"])["id"] + '.json'
    )
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/plain"
        },
        "body": '[OK]'
    }