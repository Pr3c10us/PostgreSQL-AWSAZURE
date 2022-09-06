
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_rds" {
  name        = "lambda_rds"
  path        = "/"
  description = "IAM policy for rds from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:*"
      ],
      "Resource": "arn:aws:rds:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_route53" {
  name        = "lambda_route53"
  path        = "/"
  description = "IAM policy for route53 from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "route53:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}




resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_rds.arn
}


resource "aws_iam_role_policy_attachment" "lambda_route53" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_route53.arn
}


# Logs Resources

resource "aws_cloudwatch_log_group" "snapshot_lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "create_lambda_logs" {
  name              = "/aws/lambda/${var.create_database_function}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "switch_blue_to_green_function_logs" {
  name              = "/aws/lambda/${var.switch_blue_to_green_function}"
  retention_in_days = 7
}


# Lambda Function

resource "aws_lambda_function" "rds_create_snaphsot" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/python/replicate_function.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.handler"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_rds,
    aws_cloudwatch_log_group.snapshot_lambda_logs
  ]
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/python/replicate_function.zip")
  timeout = 60
}

resource "aws_lambda_function" "rds_create_instance" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/python/create_database_instance_function.zip"
  function_name = var.create_database_function
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "create_database_instance_function.handler"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_rds,
    aws_iam_role_policy_attachment.lambda_route53,
    aws_cloudwatch_log_group.create_lambda_logs,
  ]
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/python/create_database_instance_function.zip")
  timeout = 60
 
  environment {
    variables = {
      hosted_zone_id = "${aws_route53_zone.private.zone_id}"
    }
  }
}

resource "aws_lambda_function" "switch_blue_green_function" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/python/switch_blue_to_green_function.zip"
  function_name = var.switch_blue_to_green_function
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "switch_blue_to_green_function.handler"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_route53,
    aws_cloudwatch_log_group.create_lambda_logs,
  ]
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/python/switch_blue_to_green_function.zip")
  timeout = 60
 
  environment {
    variables = {
      hosted_zone_id = "${aws_route53_zone.private.zone_id}"
    }
  }
}



# database parameter group to help adjust replicate settings




# EventBridge Events

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_create_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.console.arn
}

resource "aws_cloudwatch_event_target" "yada" {
  rule      = aws_cloudwatch_event_rule.console.name
  arn       = aws_lambda_function.rds_create_instance.arn
}

resource "aws_cloudwatch_event_rule" "console" {
  name        = "capture-rds-events"
  description = "Capture all RDS Snapshot events"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.rds"
  ],
  "detail-type": ["RDS DB Snapshot Event","RDS DB Instance Event"]
}
PATTERN
}



# Hosted Zone for Routing


resource "aws_route53_zone" "private" {
  name = "app.database"

  vpc {
    vpc_id = var.aws_vpc_id # this vpc should set both EnableDnsSupport,EnableDnsHostnames to true
  }
}


# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.private.zone_id
#   name    = "blue_database.app.database"
#   type    = "CNAME"
#   ttl     = "60"
#   records = [var.blue_database_host]
# }