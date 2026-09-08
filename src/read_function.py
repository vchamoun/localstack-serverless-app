import json, os, decimal
import boto3

# Same coldstart pattern as the writer - fail fast if TABLE_NAME is missing.
table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _json_default(value):
    # DynamoDB returns numbers as Decimal, which json.dumps refuses to serialize.
    if isinstance(value, decimal.Decimal): 
        if value == value.to_integral_value(): #If the value of rouding this number is the same as the actual number.
            return int(value) # Return an integer
        return float(value)    # Return a float
    raise TypeError("Not JSON serializable: " + str(type(value))) # 


def lambda_handler(event, context):
    print(json.dumps(event)) #Logging the caller payload.

    try:
        items = []
        kwargs = {}

        # Scan returns at most 1 MB per call, so follow the pages.
        while True:
            page = table.scan(**kwargs) 
            items.extend(page.get("Items", []))
            if "LastEvaluatedKey" not in page: #If I stop at 1 MB, I'll fetch LastEvaluatedKey
                break
            kwargs["ExclusiveStartKey"] = page["LastEvaluatedKey"] # And start my scan from it.

        body = {"count": len(items), "items": items} # Return the count and the list of items.

        return {
            # Return a 200 with the items and HTTP Headers.
            "statusCode": 200,  
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(body, default=_json_default),
        }

    except Exception as exc:
        # Return a real 500 instead of letting API Gateway turn a crash into a 502.
        print("ERROR: " + str(exc))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Internal server error"}),
        }
