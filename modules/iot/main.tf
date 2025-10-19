# =========================
# SmartPlant Guardian - IoT Core (DEV)
# =========================

locals {
  project_name = "plantx"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -------------------------
# IoT Thing (device)
# -------------------------
resource "aws_iot_thing" "plant_device" {
  name = "${local.project_name}-plant-device-dev"

  attributes = {
    type       = "plant_sensor"
    location   = "living_room"
    plant_type = "tomato"
  }
}

# -------------------------
# IoT Certificate
# -------------------------
resource "aws_iot_certificate" "device_cert" {
  active = true
}

# -------------------------
# IoT Policy for the device
# -------------------------
resource "aws_iot_policy" "device_policy" {
  name = "${local.project_name}-device-policy-dev"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = "arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:client/${local.project_name}-*"
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Publish"]
        Resource = "arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:topic/${local.project_name}/sensors/*"
      }
    ]
  })
}

# -------------------------
# Attach Policy to Certificate
# -------------------------
resource "aws_iot_policy_attachment" "device_policy_attach" {
  policy = aws_iot_policy.device_policy.name
  target = aws_iot_certificate.device_cert.arn
}

# -------------------------
# Attach Certificate to Thing
# -------------------------
resource "aws_iot_thing_principal_attachment" "device_attachment" {
  thing     = aws_iot_thing.plant_device.thing_name
  principal = aws_iot_certificate.device_cert.arn
}

# -------------------------
# IAM Role for IoT Rule -> DynamoDB
# -------------------------
resource "aws_iam_role" "iot_rule_role" {
  name = "${local.project_name}-iot-rule-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "iot.amazonaws.com"
      }
    }]
  })
}

# -------------------------
# IoT Topic Rule - Route sensor data to DynamoDB
# -------------------------


# -------------------------
# IoT Topic Rule - Trigger Lambda for low soil moisture
# -------------------------
resource "aws_iot_topic_rule" "low_moisture_alert" {
  name        = "${local.project_name}_low_moisture_dev"
  description = "Trigger Lambda on low soil moisture"
  enabled     = true
  sql         = "SELECT * FROM '${local.project_name}/sensors/+' WHERE soil_moisture < 30"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.process_sensor.arn
  }
}

# -------------------------
# IoT Topic Rule - Extreme temperature alert
# -------------------------
resource "aws_iot_topic_rule" "extreme_temp_alert" {
  name        = "${local.project_name}_extreme_temp_dev"
  description = "Trigger Lambda on extreme temperature"
  enabled     = true
  sql         = "SELECT * FROM '${local.project_name}/sensors/+' WHERE temperature < 10 OR temperature > 35"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.process_sensor.arn
  }
}
