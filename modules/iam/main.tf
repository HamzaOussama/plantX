# Lambda role - LEAST PRIVILEGE
resource "aws_iam_role" "lambda_role" {
  name = "plantX-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


# Only DynamoDB write permission
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = [
        var.sensor_table_arn,
        var.health_table_arn,
        var.alerts_table_arn
      ]
    }]
  })
}

# SNS publish permission
resource "aws_iam_role_policy" "lambda_sns" {
  name = "lambda-sns-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["sns:Publish"]
      Resource = var.sns_topic_arn
    }]
  })
}

# CloudWatch logs
resource "aws_iam_role_policy" "lambda_logs" {
  name = "lambda-logs-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# IoT Core rule role
resource "aws_iam_role" "iot_rule_role" {
  name = "plantX-iot-rule-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "iot.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy" "iot_dynamodb" {
  name = "iot-dynamodb-policy"
  role = aws_iam_role.iot_rule_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:PutItem"]
      Resource = var.sensor_table_arn
    }]
  })
}