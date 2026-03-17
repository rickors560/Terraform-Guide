"""Lambda handler: POST /items — Create a new item in DynamoDB."""

import json
import os
import uuid
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    """Create a new item.

    Expects a JSON body with at least a "name" field.
    Generates a UUID for the item id and adds timestamps.
    """
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Invalid JSON in request body"})

    if not body.get("name"):
        return _response(400, {"error": "'name' field is required"})

    now = datetime.now(timezone.utc).isoformat()
    item = {
        "id": str(uuid.uuid4()),
        "name": body["name"],
        "description": body.get("description", ""),
        "created_at": now,
        "updated_at": now,
    }

    # Merge any additional fields from the request
    for key, value in body.items():
        if key not in item:
            item[key] = value

    table.put_item(Item=item)

    return _response(201, item)


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, default=str),
    }
