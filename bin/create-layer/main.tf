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

resource "aws_s3_bucket_object" "layer_zip" {
  bucket = aws_s3_bucket.this.bucket
  key    = "lambda_layer.zip"
  source = "lambda_layer_payload.zip"
  etag   = filemd5("lambda_layer_payload.zip")
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "oracle-lambda-layer"
  s3_bucket           = aws_s3_bucket.this.bucket
  s3_key              = aws_s3_bucket_object.layer_zip.id
  compatible_runtimes = ["python3.8"]
}