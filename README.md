## LocalStack Terraform Serverless App

Terraform Configuration for an S3 -> Lambda -> DynamoDB pipeline with an API Gateway read path.
Runnable agains LocalStack or real AWS Accounts.

## Architecture

<img width="938" height="705" alt="s3-lambda-dynamodb-apigw-topology drawio" src="https://github.com/user-attachments/assets/fe5d718b-88a9-4c1a-ac98-cc75cbaa4af0" />


1. S3 bucket notification calling a Lambda function whenever an object is created or removed from the bucket;
2. The Lambda prints the incoming event in a json format and processes each attribute to the dynamodb table and logs it into CW Logs;
3. API Gateway with GET endpoints with the list of the entries from DynamoDB 


## Prerequisites

| Tool | Why | Notes |
|---|---|---|
| **Docker** | Runs the LocalStack container, and LocalStack runs Lambda in sibling containers | Daemon must be running, not just installed |
| **Terraform** | Applies the configuration | `>= 1.2` per `terraform.tf` |
| **LocalStack account** | `docker-compose.yml` requires an auth token | Free account; needed for `ENFORCE_IAM` |
| **`lstk`** | Points Terraform at LocalStack without editing the config | LocalStack CLI |
| **`awslocal`** | Used by `scripts/test.sh` to talk to LocalStack | `pip install awscli-local`; requires the AWS CLI |
| **`jq`** | Parses JSON in the test script | |


## Quickstart

**1. Add your LocalStack auth token**

Create a `.env` file at the repo root (gitignored, never commit it):

```
LOCALSTACK_AUTH_TOKEN=ls-...
```

**2. Start LocalStack**

```bash
docker compose up -d
```

**3. Select the LocalStack workspace**

```bash
terraform workspace new localstack   # first time
terraform workspace select localstack # afterwards
```

> *Always confirm with
> `terraform workspace show` before applying.

**4. Deploy**

```bash
lstk --endpoint-url http://localhost:4566 terraform init
lstk --endpoint-url http://localhost:4566 terraform apply
```

**5. Verify**

```bash
lstk status
```
            


## Structure
```
.
├── terraform.tf            Provider versions, AWS provider config, caller-identity data source
├── variables.tf            Input variables: region, bucket name, table name, runtime
├── outputs.tf              Bucket name, table name, REST API ID, endpoint URL
├── storage.tf              S3 bucket and DynamoDB table
├── writer.tf               Write path: S3 event → Lambda → DynamoDB
├── reader.tf               Read path: Lambda that scans the table
├── apigw.tf                REST API exposing GET /files
│
├── src/
│   ├── writer_function.py  Indexes object metadata on ObjectCreated / ObjectRemoved
│   └── read_function.py     Returns table contents as an API Gateway proxy response
│
├── scripts/
│   └── test.sh             Exercises the full chain via awslocal
│
├── logs/
│   ├── localstack-iam-disabled.log   Debug log, ENFORCE_IAM=0 (full deploy succeeds)
│   └── localstack-iam-enforced.log   Debug log, ENFORCE_IAM=1 (bucket notification denied)
│
├── docker-compose.yml      LocalStack container, debug logging enabled
└── s3-lambda-dynamodb-apigw-topology.drawio   Editable architecture diagram
```
## Testing

### Automated

```bash
./scripts/test.sh
```

Runs the full chain and asserts each step. Exits non-zero on failure.

### Step by step

**Read the resource names from Terraform outputs.tf**

```bash
BUCKET=$(terraform output -raw bucket_name)
TABLE=$(terraform output -raw table_name)
API=$(terraform output -raw rest_api_id)
```

**1. Upload a text file to S3**

```bash
echo hello > /tmp/hello.txt
awslocal s3 cp /tmp/hello.txt "s3://$BUCKET/hello.txt"
```

**2. Confirm the Lambda ran**

```bash
awslocal logs tail /aws/lambda/writer_lambda_function --since 5m
```

Expect the S3 event printed as JSON, followed by a `REPORT` line.

**3. Confirm the metadata was written**

```bash
awslocal dynamodb scan --table-name "$TABLE"
```

Expect one item with `fileName`, `extension` and `size`.

**4. Read the data back through the API**

```bash
curl -i "http://localhost:4566/restapis/$API/dev/_user_request_/files"
```

Expect `200` and `{"count": 1, "items": [...]}`.

**5. Confirm deletes are handled**

```bash
awslocal s3 rm "s3://$BUCKET/hello.txt"
awslocal dynamodb scan --table-name "$TABLE" --select COUNT
```

Expect `Count` back to `0`.

> `terraform output files_endpoint` returns an AWS-style hostname that does **not**
> resolve against LocalStack. Use the path form in step 4 locally.
