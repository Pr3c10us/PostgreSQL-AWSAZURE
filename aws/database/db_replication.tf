module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "education"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "education" {
  name       = "education"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "Education"
  }
}

# resource "aws_db_security_group" "rds" {
#   name = "rds_sg"

#   ingress {
#     cidr = "10.0.0.0/24"
#   }
# }

resource "aws_db_parameter_group" "postgres14_replication_params" {
  name   = "postgres14_replication_params"
  family = "postgres14"

  parameter {
    name  = "rds.logical_replication"
    value = 1
    apply_method = "pending-reboot"

  }
  
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pglogical"
    apply_method = "pending-reboot"
  }
  
  parameter {
    name  = "pglogical.conflict_resolution"
    value = "last_update_wins"
  }
  
  parameter {
    name  = "track_commit_timestamp"
    value = 1
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "master_db" {
  allocated_storage    = 30
  engine               = "postgres"
  engine_version       = "14.1"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = aws_db_parameter_group.postgres14_replication_params.name
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_db" {
  allocated_storage    = 30
  engine               = "postgres"
  engine_version       = "14.1"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = aws_db_parameter_group.postgres14_replication_params.name
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot  = true
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_replication_function"

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
    }
  ]
}
EOF
}


resource "aws_iam_policy" "lambda_logging" {
  name        = "replication_logging"
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
  name        = "replication_rds"
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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_rds.arn
}

resource "aws_cloudwatch_log_group" "master_replication_function" {
  name              = "/aws/lambda/${var.create_database_function}"
  retention_in_days = 7
}

resource "aws_lambda_function" "master_replication_function" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/python/master_replication_function.zip"
  function_name = var.master_replication_function
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "master_replication_function.handler"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.create_lambda_logs,
  ]
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/python/master_replication_function.zip")
  timeout = 60

  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = [aws_subnet.subnet_for_lambda.id]
    security_group_ids = [aws_security_group.sg_for_lambda.id]
  }
}
