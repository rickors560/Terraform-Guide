"""Lambda handler: DELETE /items/{id} — Delete an item from DynamoDB."""

import json
import os

import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    """Delete an item by its id.

    Returns 404 if the item does not exist (uses ConditionExpression).
    """
    item_id = event.get("pathParameters", {}).get("id")

    if not item_id:
        return _response(400, {"error": "Missing 'id' path parameter"})

    try:
        table.delete_item(
            Key={"id": item_id},
            ConditionExpression="attribute_exists(id)",
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return _response(404, {"error": f"Item '{item_id}' not found"})
        raise

    return _response(200, {"message": f"Item '{item_id}' deleted successfully"})


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, default=str),
    }
