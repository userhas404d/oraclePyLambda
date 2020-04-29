resource "random_string" "this" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = "${var.project_name}-layer"
  acl           = "private"

  tags = {
    Name        = "${var.project_name}-layer"
    Description = "Holds the ${var.project_name}-layer resources"
  }

  versioning {
    enabled = true
  }
}

locals {
  python_layer_zip_path = "./bin/create-layer/python.zip"
  oracle_layer_zip_path = "./bin/create-layer/oracle-instant-client.zip"
  lib_layer_zip_path    = "./bin/create-layer/lib.zip"
}

# resource "aws_s3_bucket_object" "oracle_layer_zip" {
#   bucket = aws_s3_bucket.this.bucket
#   key    = "oracle_lambda_layer.zip"
#   source = local.oracle_layer_zip_path
#   etag   = filemd5(local.oracle_layer_zip_path)
# }

# resource "aws_lambda_layer_version" "oracle_lambda_layer" {
#   layer_name          = "${var.project_name}-cx-oracle"
#   s3_bucket           = aws_s3_bucket.this.bucket
#   s3_key              = aws_s3_bucket_object.oracle_layer_zip.id
#   compatible_runtimes = ["python3.7"]
# }

resource "aws_s3_bucket_object" "lib_layer_zip" {
  bucket = aws_s3_bucket.this.bucket
  key    = "lib_lambda_layer.zip"
  source = local.lib_layer_zip_path
  etag   = filemd5(local.lib_layer_zip_path)
}

resource "aws_lambda_layer_version" "lib_lambda_layer" {
  layer_name          = "${var.project_name}-lib"
  s3_bucket           = aws_s3_bucket.this.bucket
  s3_key              = aws_s3_bucket_object.lib_layer_zip.id
  compatible_runtimes = ["python3.7"]
}

resource "aws_s3_bucket_object" "python_layer_zip" {
  bucket = aws_s3_bucket.this.bucket
  key    = "python_lambda_layer.zip"
  source = local.python_layer_zip_path
  etag   = filemd5(local.python_layer_zip_path)
}

resource "aws_lambda_layer_version" "python_lambda_layer" {
  layer_name          = "${var.project_name}-python"
  s3_bucket           = aws_s3_bucket.this.bucket
  s3_key              = aws_s3_bucket_object.python_layer_zip.id
  compatible_runtimes = ["python3.7"]
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-ldap-query-sg-${random_string.this.result}"
  description = "SG used by the ${var.project_name}-ldap-query-sg lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda"

  function_name = "${var.project_name}-${random_string.this.result}"
  description   = "Performs oracle db operations"
  handler       = "lambda.handler"
  runtime       = "python3.7"
  timeout       = 300

  source_path = "${path.module}/lambda"
  environment = {
    variables = var.env_vars
  }

  vpc_config = {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
  layers = [
    "${aws_lambda_layer_version.python_lambda_layer.arn}",
    "${aws_lambda_layer_version.lib_lambda_layer.arn}"
  ]
}