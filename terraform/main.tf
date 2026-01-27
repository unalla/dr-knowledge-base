# 1. Package the Python code from your lambda_functions folder
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_functions/lambda.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# 2. IAM Role for the Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "dr_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 3. Attach basic logging and S3 read permissions
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3_read_policy" {
  name = "lambda_s3_read_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::dr-ai-runbooks/runbooks/*"]
    }]
  })
}

# 4. Define the Lambda Function
resource "aws_lambda_function" "ingest_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "dr-runbook-ingestor"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda.lambda_handler" # filename.function_name
  runtime          = "python3.11"
  timeout          = 30

  # Inject your API keys from terraform.tfvars
  environment {
    variables = {
      PINECONE_API_KEY = var.pinecone_api_key
      OPENAI_API_KEY   = var.openai_api_key
    }
  }
}

# 5. Permission for S3 to trigger the Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::dr-ai-runbooks"
}

# 6. S3 Bucket Notification (The Trigger)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "dr-ai-runbooks"

  lambda_function {
    lambda_function_arn = aws_lambda_function.ingest_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "runbooks/"
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}