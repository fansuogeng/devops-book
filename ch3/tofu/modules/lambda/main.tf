resource "aws_lambda_function" "function" {
  function_name = var.name
  role          = aws_iam_role.lambda.arn

  package_type     = "Zip"
  filename         = data.archive_file.source_code.output_path
  source_code_hash = data.archive_file.source_code.output_base64sha256

  runtime = var.runtime
  handler = var.handler

  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = var.environment_variables
  }
}

data "archive_file" "source_code" {
  type        = "zip"
  source_dir  = var.src_dir
  output_path = "${path.module}/${var.name}.zip"
}

resource "aws_iam_role" "lambda" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "allow_logging" {
  name   = "${var.name}-allow-logging"
  role   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.allow_logging.json
}

data "aws_iam_policy_document" "allow_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_lambda_function_url" "url" {
  count              = var.create_url ? 1 : 0
  function_name      = aws_lambda_function.function.function_name
  authorization_type = "NONE"
}

# NONE auth: AWS requires both InvokeFunctionUrl and InvokeFunction (via URL only).
resource "aws_lambda_permission" "function_url_public" {
  count = var.create_url ? 1 : 0

  statement_id           = "${var.name}-function-url-public"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.function.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "function_url_invoke" {
  count = var.create_url ? 1 : 0

  statement_id             = "${var.name}-function-url-invoke"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.function.function_name
  principal                = "*"
  invoked_via_function_url = true
}