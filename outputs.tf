/**
 * SmartPlant Guardian - Terraform Outputs
 * Export important values for reference
 */

output "iot_endpoint" {
  description = "AWS IoT Core endpoint for device connection"
  value       = "iot.${data.aws_region.current.id}.amazonaws.com"
}

output "iot_thing_name" {
  description = "IoT Thing name"
  value       = aws_iot_thing.plant_sensor.name
}

output "sensor_table_name" {
  description = "DynamoDB sensor readings table"
  value       = aws_dynamodb_table.sensor_readings.name
}

output "health_table_name" {
  description = "DynamoDB health predictions table"
  value       = aws_dynamodb_table.health_predictions.name
}

output "alerts_table_name" {
  description = "DynamoDB alerts table"
  value       = aws_dynamodb_table.alerts.name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.process_sensor.function_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.smartplant.dashboard_name}"
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    region      = data.aws_region.current.id
    account_id  = data.aws_caller_identity.current.account_id
    environment = var.environment
  }
}