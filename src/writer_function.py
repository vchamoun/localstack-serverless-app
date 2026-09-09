import json, os, urllib.parse
import boto3

# Adding the table in the coldstart so it fails fast.
table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    # print the S3 event in json so Lambda handles it easily.
    print(json.dumps(event))

    # Safeguarding from s3:TestEvent
    if "Records" not in event:
        print("No Records array (likely s3:TestEvent) - nothing to do")
        return {"skipped": True}

    # Counter so the return value carries real information.
    processed = 0

    # Process the array of records
    for rec in event["Records"]:
        # rec.get withstands null eventNames without failing the Lambda Function.
        name = rec.get("eventName", "")
        # Record the s3 and object dicts.
        obj = rec["s3"]["object"]
        # Fix the URL encoding in the keys.
        key = urllib.parse.unquote_plus(obj["key"])

        # Console-created folders are 0-byte objects ending in "/" - skip them.
        if key.endswith("/"):
            print("Skipping folder placeholder object: " + key)
            continue

        # Removing the prefixes out of the keys by removing everything behind the /.
        base = key.rsplit("/", 1)[-1]
        # lowercase and strip the . from extensions.
        ext = os.path.splitext(base)[1].lower().lstrip(".")

        # If the event is an upload, it'll be processed.
        if name.startswith("ObjectCreated:"):
            table.put_item(
                Item={
                    "fileName": key,
                    "extension": ext,
                    "size": int(obj.get("size", 0)),
                }
            )
            processed += 1
        # If the event is a delete, it'll be removed from the DB.
        elif name.startswith("ObjectRemoved:"):
            table.delete_item(Key={"fileName": key})
            processed += 1
        # Everything else is not worked.
        else:
            print("Unhandled eventName: " + name)

    return {"processed": processed}
