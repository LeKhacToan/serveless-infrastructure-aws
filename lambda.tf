# Lambda function
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.project_name}_iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lamba_exec_role_eni" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.project_name}_api"
  role          = aws_iam_role.iam_for_lambda.arn
  depends_on    = [aws_iam_role_policy_attachment.lamba_exec_role_eni]
  package_type  = "Image"

  image_uri = "069217422023.dkr.ecr.us-west-2.amazonaws.com/serverless-test:test-1"

  environment {
    variables = {
      foo = "bar"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_sn_1.id, aws_subnet.private_sn_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# API gateway
resource "aws_api_gateway_rest_api" "lambda_api" {
  name = "${var.project_name}_api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_integration_response" "response_proxy_integration" {
   rest_api_id = aws_api_gateway_rest_api.lambda_api.id
   resource_id = aws_api_gateway_resource.proxy.id
   http_method = aws_api_gateway_method.proxy_method.http_method
   status_code = "200"

   response_templates = {
     "application/json" = ""
   } 
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "response_proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "response_proxy_root_integration" {
   rest_api_id = aws_api_gateway_rest_api.lambda_api.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method
   status_code = "200"

   response_templates = {
     "application/json" = ""
   } 
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "apigw_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API
  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_lambda_2" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*/" portion grants access from any method on any resource
  # within the API Gateway REST API
  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*/"
}

output "base_url" {
  value = aws_api_gateway_deployment.deploy.invoke_url
}

