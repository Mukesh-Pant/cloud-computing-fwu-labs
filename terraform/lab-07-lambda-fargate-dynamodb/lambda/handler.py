"""Lab 7 - Visitor logger Lambda function.

On each invocation, writes a record to the DynamoDB table 'visitors-mukesh'
with a generated UUID, current timestamp, and identifying name.
"""
import json
import os
import time
import uuid

import boto3

ddb = boto3.client("dynamodb")
TABLE = os.environ["TABLE_NAME"]


def handler(event, context):
    item_id = str(uuid.uuid4())
    now = int(time.time())

    ddb.put_item(
        TableName=TABLE,
        Item={
            "id":        {"S": item_id},
            "timestamp": {"N": str(now)},
            "name":      {"S": "Mukesh"},
            "source":    {"S": "lambda-mukesh-visitor-logger"},
            "lab":       {"S": "FWU Cloud Computing Lab 7"},
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message":  "Visitor entry recorded",
            "id":       item_id,
            "timestamp": now,
            "wrote_to": TABLE,
        }),
    }
