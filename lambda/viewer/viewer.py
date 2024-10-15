import boto3, os, json
from datetime import datetime

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    # retrieve all objects
    objects = s3.list_objects_v2(Bucket=os.environ['BUCKET_NAME'])

    result_array = []

    for obj in objects.get('Contents', []):
        object_key = obj['Key']
        datetime_string = datetime.strptime(object_key.split('.')[0], '%d%m%Y_%H%M%S').strftime('%Y-%m-%dT%H:%M:%SZ')
        response = s3.get_object(Bucket=os.environ['BUCKET_NAME'], Key=object_key)
        data = json.loads(response['Body'].read().decode('utf-8'))
        data.update({"timestamp": datetime_string})
        result_array.append(data)
    
    result_array.reverse()
    body = str(result_array)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }