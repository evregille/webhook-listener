from datetime import datetime

import boto3, os, json

def lambda_handler(event, context):
    now = datetime.now()
    s3 = boto3.resource('s3')
    object = s3.Object(os.environ['BUCKET_NAME'], now.strftime("%d%m%Y_%H%M%S")+'.json')
    object.put(Body=event["body"])
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/plain"
        },
        "body": '[accepted]'
    }