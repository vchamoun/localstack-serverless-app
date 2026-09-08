
resource "aws_api_gateway_rest_api" "apigw_get" { #API Container
  name        = "filemetadata-api"
  description = "Read API for the S3 file metadata index"
  endpoint_configuration {
    types = ["REGIONAL"] #Regional resource. No Cloudfront.
  }
}


resource "aws_api_gateway_resource" "files" { #path 
  rest_api_id = aws_api_gateway_rest_api.apigw_get.id
  parent_id   = aws_api_gateway_rest_api.apigw_get.root_resource_id
  path_part   = "files"
}

resource "aws_api_gateway_method" "files_get" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_get.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "GET"
  authorization = "NONE" #No Authentication.
}

resource "aws_api_gateway_integration" "files_get" {
  rest_api_id             = aws_api_gateway_rest_api.apigw_get.id
  resource_id             = aws_api_gateway_resource.files.id
  http_method             = aws_api_gateway_method.files_get.http_method   #Linking the method to the apigw.
  integration_http_method  = "POST"
  type                    = "AWS_PROXY"                                    #Lambda Proxy Integration.
  uri                     = aws_lambda_function.reader_function.invoke_arn #pre-formatted URI from the Lambda.
}



resource "aws_api_gateway_deployment" "apigw_get_deployment" {
  rest_api_id = aws_api_gateway_rest_api.apigw_get.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.files,
      aws_api_gateway_method.files_get,
      aws_api_gateway_integration.files_get,
    ]))
  }
  lifecycle {
    create_before_destroy = true #AWS forbids deleting a deploy,ent if a stage is currently pointing to it.
  }
  depends_on = [
    aws_api_gateway_method.files_get,
    aws_api_gateway_integration.files_get,
  ]
}


resource "aws_api_gateway_stage" "apigw_get_stage" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_get.id
  deployment_id = aws_api_gateway_deployment.apigw_get_deployment.id
  stage_name    = "dev"
}


output "files_endpoint" {
  description = "Full URL of the GET /files endpoint"
  value       = "${aws_api_gateway_stage.apigw_get_stage.invoke_url}/files"
}
