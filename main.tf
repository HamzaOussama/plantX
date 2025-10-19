/**
 * SmartPlant Guardian - AWS Cloud Infrastructure (Dev Only)
 * Deploy with:
 * terraform init
 * terraform plan -var-file=environments/dev.tfvars
 * terraform apply -var-file=environments/dev.tfvars
 */

# ============================================================================
# LOCALS
# ============================================================================
locals {
  project_name = "plantx"
  common_tags = {
    Application = "plantx"
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# 1. AWS IoT CORE - Device Connectivity
# ============================================================================
resource "aws_iot_thing" "plant_sensor" {
  name = "${local.project_name}-sensor-dev-001"

  attributes = {
    type       = "plant_sensor"
    location   = "home"
    plant_type = "tomato"
  }
}

resource "aws_iot_certificate" "device_cert" {
  active = true
}

resource "local_file" "device_cert_pem" {
  filename = "${path.module}/device-cert.pem"
  content  = aws_iot_certificate.device_cert.certificate_pem
}

resource "local_file" "device_cert_private" {
  filename        = "${path.module}/device-private.key"
  content         = aws_iot_certificate.device_cert.private_key
  file_permission = "0600"
}

resource "aws_iot_policy" "device_policy" {
  name = "${local.project_name}-device-policy-dev"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = ["arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:client/${local.project_name}-*"]
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Publish"]
        Resource = ["arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:topic/${local.project_name}/sensors/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Subscribe", "iot:Receive"]
        Resource = ["arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:topicfilter/${local.project_name}/commands/*"]
      }
    ]
  })
}

resource "aws_iot_policy_attachment" "device_policy_attach" {
  policy = aws_iot_policy.device_policy.id
  target = aws_iot_certificate.device_cert.arn
}

resource "aws_iot_thing_principal_attachment" "device_attachment" {
  thing     = aws_iot_thing.plant_sensor.name
  principal = aws_iot_certificate.device_cert.arn
}

# ============================================================================
# 2. DYNAMODB - Sensor Data Storage
# ============================================================================
resource "aws_kms_key" "dynamodb_key" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${local.project_name}-dynamodb-key"
  }
}

resource "aws_kms_alias" "dynamodb_key_alias" {
  name          = "alias/${local.project_name}-dynamodb"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

resource "aws_dynamodb_table" "sensor_readings" {
  name         = "${local.project_name}-sensor-readings-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "expire_at"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  tags = merge(local.common_tags, { Name = "${local.project_name}-sensors" })
}

resource "aws_dynamodb_table" "health_predictions" {
  name         = "${local.project_name}-health-predictions-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  tags = merge(local.common_tags, { Name = "${local.project_name}-health" })
}

resource "aws_dynamodb_table" "alerts" {
  name         = "${local.project_name}-alerts-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alert_id"
  range_key    = "timestamp"

  attribute {
    name = "alert_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "expire_at"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  tags = merge(local.common_tags, { Name = "${local.project_name}-alerts" })
}

# ============================================================================
# 3. IAM ROLES & POLICIES
# ============================================================================
resource "aws_iam_role" "lambda_role" {
  name = "${local.project_name}-lambda-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${local.project_name}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource = [
          aws_dynamodb_table.sensor_readings.arn,
          aws_dynamodb_table.health_predictions.arn,
          aws_dynamodb_table.alerts.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_sns" {
  name = "${local.project_name}-lambda-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.project_name}-lambda-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================================================
# 4. LAMBDA FUNCTION
# ============================================================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "process_sensor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${local.project_name}-process-sensor-dev"
  role          = aws_iam_role.lambda_role.arn
  handler       = "process_sensor_data.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_HEALTH_TABLE = aws_dynamodb_table.health_predictions.name
      DYNAMODB_ALERTS_TABLE = aws_dynamodb_table.alerts.name
      SNS_TOPIC_ARN         = aws_sns_topic.alerts.arn
      ENVIRONMENT           = "dev"
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_iot" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_sensor.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = "arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:rule/*"
}

# ============================================================================
# 5. IoT TOPIC RULES
# ============================================================================
resource "aws_iam_role" "iot_rule_role" {
  name = "${local.project_name}-iot-rule-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "iot.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_dynamodb" {
  name = "${local.project_name}-iot-dynamodb-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.sensor_readings.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_lambda" {
  name = "${local.project_name}-iot-lambda-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.process_sensor.arn
      }
    ]
  })
}

# IoT Rule - DynamoDB
#resource "aws_iot_topic_rule" "sensor_to_dynamodb" {
# name        = "${local.project_name}_sensor_to_dynamodb_dev"
# description = "Route sensor data to DynamoDB"
# enabled     = true
# sql         = "SELECT device_id, timestamp, moisture, temperature FROM '${local.project_name}/sensors/+'"
# sql_version = "2016-03-23"

#  dynamodb {
#   table_name      = aws_dynamodb_table.sensor_readings.name
#   role_arn        = aws_iam_role.iot_rule_role.arn
#   hash_key_field  = "device_id"
#  hash_key_value  = "${sql_result.device_id}"  # replace with actual field from SQL
#  range_key_field = "timestamp"
#   range_key_value = "${sql_result.timestamp}"
## }
#}

# Lambda - KMS decrypt policy
resource "aws_iam_role_policy" "lambda_kms" {
  name = "${local.project_name}-lambda-kms-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      Resource = aws_kms_key.dynamodb_key.arn
    }]
  })
}

# IoT Rule -> Invoke Lambda when soil_moisture < 30
resource "aws_iot_topic_rule" "sensor_to_lambda" {
  name        = "${local.project_name}_process_rule_dev"
  description = "Invoke Lambda to process sensor messages (health predictions)"
  enabled     = true
  sql_version = "2016-03-23"
  # make sure this matches the topics you publish to (you publish to plantx/sensors/...)
sql = "SELECT * FROM 'plantx/sensors/+' WHERE soil_moisture < 30"

  lambda {
    function_arn = aws_lambda_function.process_sensor.arn
  }

  # optional: tag or error action can be added here
}

resource "aws_lambda_permission" "allow_iot_invoke" {
  statement_id  = "AllowExecutionFromIoTV2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_sensor.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.sensor_to_lambda.arn
}



# ============================================================================
# 6. SNS - Alerts
# ============================================================================
resource "aws_sns_topic" "alerts" {
  name              = "${local.project_name}-alerts-dev"
  kms_master_key_id = aws_kms_key.dynamodb_key.id
  tags              = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================================
# 7. S3 DATA LAKE
# ============================================================================
resource "aws_kms_key" "cw_logs_key" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccountUsage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_kms_alias" "cw_logs_key_alias" {
  name          = "alias/plantx-guardian-logs"
  target_key_id = aws_kms_key.cw_logs_key.id
}

# ============================================================================
# 8. CLOUDWATCH
# ============================================================================
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/plantx-process-sensor-dev"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cw_logs_key.arn
}


resource "aws_cloudwatch_dashboard" "smartplant" {
  dashboard_name = "${local.project_name}-dev"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/IoT", "Publish.In.Success", { stat = "Sum" }],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", { stat = "Sum" }],
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            ["AWS/Lambda", "Errors", { stat = "Sum" }],
            ["AWS/Lambda", "Duration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.id
          title  = "SmartPlant System Metrics"
        }
      }
    ]
  })
}

# ============================================================================
#  CloudWatch Dashboard
# ============================================================================
resource "aws_cloudwatch_dashboard" "plantx_dashboard" {
  dashboard_name = "${local.project_name}-dev"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          title = "Soil Moisture (Average)",
          metrics = [
            [ "AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", aws_dynamodb_table.sensor_readings.name ]
          ],
          view = "timeSeries",
          stacked = false,
          region = var.region,
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 7,
        width = 12,
        height = 6,
        properties = {
          title = "Lambda Invocations & Errors",
          metrics = [
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.process_sensor.function_name ],
            [ ".", "Errors", ".", "." ]
          ],
          view = "timeSeries",
          stacked = false,
          region = var.region
        }
      }
    ]
  })
}