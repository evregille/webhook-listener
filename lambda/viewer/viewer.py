import boto3, os, json

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    # retrieve all objects
    objects = s3.list_objects_v2(Bucket=os.environ['BUCKET_NAME'])

    result_array = []

    for obj in objects.get('Contents', []):
        object_key = obj['Key']
        response = s3.get_object(Bucket=os.environ['BUCKET_NAME'], Key=object_key)
        content = response['Body'].read().decode('utf-8')
        data = json.loads(content)
        result_array.append(data)
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": str(result_array.reverse())
    }