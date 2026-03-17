"""Lambda handler: GET /items/{id} — Retrieve a single item from DynamoDB."""

import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    """Get an item by its id from path parameters."""
    item_id = event.get("pathParameters", {}).get("id")

    if not item_id:
        return _response(400, {"error": "Missing 'id' path parameter"})

    result = table.get_item(Key={"id": item_id})
    item = result.get("Item")

    if not item:
        return _response(404, {"error": f"Item '{item_id}' not found"})

    return _response(200, item)


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, default=str),
    }
