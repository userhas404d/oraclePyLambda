resource "random_string" "this" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = "oracle-lambda-layer"
  acl           = "private"

  tags = {
    Name        = "oracle-lambda-layer"
    Description = "Holds the oracle-lambda-layer resources"
  }

  versioning {
    enabled = true
  }
}

locals {
  layer_zip_path = "./bin/create-layer/lambda_layer_payload.zip"
}

resource "aws_s3_bucket_object" "layer_zip" {
  bucket = aws_s3_bucket.this.bucket
  key    = "lambda_layer.zip"
  source = local.layer_zip_path
  etag   = filemd5(local.layer_zip_path)
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "oracle-lambda-layer"
  s3_bucket           = aws_s3_bucket.this.bucket
  s3_key              = aws_s3_bucket_object.layer_zip.id
  compatible_runtimes = ["python3.8"]
}

data "aws_iam_policy_document" "lambda" {

  statement {
    sid = "AllowS3Write"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [aws_s3_bucket.this.arn]
  }
}

module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda"

  function_name = "oracle-test-${random_string.this.result}"
  description   = "Performs oracle db operations"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  timeout       = 300


  policy      = data.aws_iam_policy_document.lambda
  source_path = "${path.module}/lambda"

  layers = ["${aws_lambda_layer_version.lambda_layer.arn}"]
}