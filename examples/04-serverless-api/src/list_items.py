"""Lambda handler: GET /items — List all items from DynamoDB."""

import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    """Scan the table and return all items.

    Supports optional 'limit' query parameter (default 100).
    Handles pagination internally for tables with many items.
    """
    params = event.get("queryStringParameters") or {}

    try:
        limit = int(params.get("limit", 100))
    except (ValueError, TypeError):
        limit = 100

    items = []
    scan_kwargs = {"Limit": limit}

    response = table.scan(**scan_kwargs)
    items.extend(response.get("Items", []))

    # Continue scanning if there are more items and we haven't hit the limit
    while "LastEvaluatedKey" in response and len(items) < limit:
        scan_kwargs["ExclusiveStartKey"] = response["LastEvaluatedKey"]
        response = table.scan(**scan_kwargs)
        items.extend(response.get("Items", []))

    items = items[:limit]

    return _response(200, {
        "items": items,
        "count": len(items),
    })


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, default=str),
    }
