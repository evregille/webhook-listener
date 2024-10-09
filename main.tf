terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Our Lambda function
resource "aws_lambda_function" "lambda-webhook" {
  filename      = "${path.module}/lambda/webhook/webhook.zip"
  function_name = "webhook"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "webhook.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  environment {
    variables = {
      BUCKET_NAME = "${aws_s3_bucket.bucket.id}"
    }
  }
}

resource "aws_lambda_function" "lambda-viewer" {
  filename      = "${path.module}/lambda/viewer/viewer.zip"
  function_name = "viewer"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "viewer.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  environment {
    variables = {
      BUCKET_NAME = "${aws_s3_bucket.bucket.id}"
    }
  }
}

# A ZIP archive containing python code
data "archive_file" "lambda-webhook" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/webhook/"
  output_path = "${path.module}/lambda/webhook/webhook.zip"
}

data "archive_file" "lambda-viewer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/viewer/"
  output_path = "${path.module}/lambda/viewer/viewer.zip"
}

# Our public HTTPS endpoint
resource "aws_lambda_function_url" "lambda_webhook_url" {
  function_name      = aws_lambda_function.lambda-webhook.arn
  authorization_type = "NONE"
}

resource "aws_lambda_function_url" "lambda_viewer_url" {
  function_name      = aws_lambda_function.lambda-viewer.arn
  authorization_type = "NONE"
  cors {
    allow_origins     = ["*"]
    allow_methods = ["GET"]
  }
}

output "webhook_url" {
  description = "Webhook Listner URL"
  value       = aws_lambda_function_url.lambda_webhook_url.function_url
}

output "viewer_url" {
  description = "Viewer URL"
  value       = aws_lambda_function_url.lambda_viewer_url.function_url
}

# A Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "lambda-webhook" {
  name = "/aws/lambda/${aws_lambda_function.lambda-webhook.function_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "lambda-viewer" {
  name = "/aws/lambda/${aws_lambda_function.lambda-viewer.function_name}"
  retention_in_days = 1
}

# IAM Role for Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "LambdaWebhookRole"
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

# IAM Policy for our Lambda
resource "aws_iam_policy" "iam_for_lambda_policy" {
  name   = "iam_for_lambda_policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "s3:PutObject",
                "*"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.bucket.id}",
                "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"
            ],
            "Effect": "Allow",
        }
    ]})
}

resource "aws_iam_policy_attachment" "policy_attachment_lambda" {
  name       = "attachmentLambdaWebhoo"
  roles      = ["${aws_iam_role.iam_for_lambda.name}"]
  policy_arn = aws_iam_policy.iam_for_lambda_policy.arn
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "delete_events" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    status = "Enabled"
    id     = "expire_all_files"
    expiration {
        days = var.events_delete_from_s3_in_days
    }
  }
}