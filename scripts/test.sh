#!/usr/bin/env bash
#
# Exercises the deployed stack end to end using awslocal:
#   upload to S3 -> writer Lambda -> DynamoDB -> API Gateway -> reader Lambda
#
# Usage: ./scripts/test.sh
# Requires: awslocal, terraform, curl, and a deployed stack in the current workspace.

set -euo pipefail

# Run from the repo root, since `terraform output` is directory-sensitive.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

BUCKET=$(terraform output -raw bucket_name)
TABLE=$(terraform output -raw table_name)
API=$(terraform output -raw rest_api_id)

echo "bucket=$BUCKET  table=$TABLE  api=$API"
echo

echo "hello from test.sh" > /tmp/hello.txt

echo "== 1. Upload an object to S3 =="
awslocal s3 cp /tmp/hello.txt "s3://$BUCKET/hello.txt"
echo

# The S3 notification invokes the Lambda asynchronously, so give it a moment.
sleep 5

echo "== 2. Writer Lambda logs =="
awslocal logs tail /aws/lambda/writer_lambda_function --since 2m
echo

echo "== 3. DynamoDB contents =="
awslocal dynamodb scan --table-name "$TABLE"
echo

echo "== 4. Read back through API Gateway =="
curl -s "http://localhost:4566/restapis/$API/dev/_user_request_/files"
echo
echo

echo "== 5. Delete the object =="
awslocal s3 rm "s3://$BUCKET/hello.txt"
sleep 5
echo

echo "== 6. DynamoDB after delete =="
awslocal dynamodb scan --table-name "$TABLE" --select COUNT
