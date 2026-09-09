**LocalStack-Terraform Serverless App**
Terraform Configuration for an S3 -> Lambda -> DynamoDB pipeline with an API Gateway read path.
Runnable agains LocalStack or real AWS Accounts.

**Architecture**
<img width="938" height="705" alt="s3-lambda-dynamodb-apigw-topology drawio" src="https://github.com/user-attachments/assets/fe5d718b-88a9-4c1a-ac98-cc75cbaa4af0" />

1/ S3 bucket notification calling a Lambda function whenever an object is created or removed from the bucket;
2/ The Lambda prints the incoming event in a json format and processes each attribute to the dynamodb table and logs it into CW Logs;
3/ API Gateway with GET endpoints with the list of the entries from DynamoDB *I decided to create a reader lambda instead of using a single function because the Reading part came afterwards.

**Quickstart**
1/ Define LOCALSTACK_AUTH_TOKEN in .env                        
2/ $docker compose up -d                                       #create and start the container defined in the compose file.
3/ $terraform workspace new localstack                         #Create the localstack workspace
4/ $lstk --endpoint-url http://localhost:4566 terraform init   #Initialize the workspace
5/ $lstk --endpoint-url http://localhost:4566 terraform apply  #Create the infrastructure in your localstack endpoint.
6/ $lstk status                                                #Shows localstack emulator status and the resources.

**Structure**

├── terraform.tf                  Provider versions, AWS provider config, caller-identity data source
├── variables.tf                  Input variables: region, bucket name, table name, runtime
├── storage.tf                    S3 bucket, DynamoDB table
├── writer.tf                     S3 event → Lambda → DynamoDB
├── reader.tf                     Lambda that scans the DynamoDB table
├── apigw.tf                      REST API exposing GET /files, plus the endpoint output
├── src/
│   ├── writer_function.py        Indexes object metadata on ObjectCreated / ObjectRemoved
│   └── read_function.py          Returns the table contents as an API Gateway proxy response
├── docker-compose.yml            LocalStack container
└── s3-lambda-dynamodb-apigw-topology.drawio    Editable architecture diagram

**Testing**
1/ **Upload a simple txt file to s3:**
    $echo hello > /tmp/hello.txt
    $aws s3 cp /tmp/hello.txt s3://s3-localstack-objrepo2/hello.txt
2/ **Check the CW Logs to confirm the lambda execution.**
    $aws logs tail /aws/lambda/writer_lambda_function
3/ **Check the DynamoDB Table**
    $aws dynamodb scan --table-name ddb-filemetadata
4/ **Fetch the API name from the terraform resource**
    $API=$(terraform show -json | jq -r '.values.root_module.resources[]
      | select(.address=="aws_api_gateway_rest_api.apigw_get") | .values.id')
5/ **Use cURL to get the data from the API**
    $curl -i "http://localhost:4566/restapis/$API/dev/_user_request_/files"




    
