resource "aws_lambda_function" "process_sensor" {
  filename      = "lambda_functions/process_sensor_data.zip"
  function_name = "plantX-process-sensor-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "process_sensor_data.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256
  
  environment {
    variables = {
      DYNAMODB_HEALTH_TABLE = var.health_table_name
      SNS_TOPIC_ARN        = var.sns_topic_arn
    }
  }
  
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
}

# IoT Core -> DynamoDB Rule
resource "aws_iot_topic_rule" "sensor_to_dynamodb" {
  name        = "plantX_sensors_rule"
  description = "Route sensor data to DynamoDB"
  enabled     = true
  sql         = "SELECT * FROM 'plantx/sensors/+'"
  sql_version = "2016-03-23" # always specify SQL version

dynamodb {
  table_name       = var.sensor_table_name
  role_arn         = aws_iam_role.iot_rule_role.arn
  hash_key_field   = "device_id"
  hash_key_value   = "${topic(3)}"            # Extract device_id from topic, e.g. plantX/sensors/device123
  range_key_field  = "timestamp"
  range_key_value  = "${timestamp()}"         # Use message timestamp
  payload_field    = "payload"                # Optional: store full message JSON
}

}

# IoT Core -> Lambda Rule (for processing)
resource "aws_iot_topic_rule" "sensor_to_lambda" {
  name        = "smartplant_process_rule"
  description = "Process sensor data with Lambda"
  enabled     = true
  sql         = "SELECT * FROM 'smartplant/sensors/+' WHERE soil_moisture < 30"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.process_sensor.arn
  }
}


resource "aws_lambda_permission" "allow_iot" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_sensor.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/*"
}