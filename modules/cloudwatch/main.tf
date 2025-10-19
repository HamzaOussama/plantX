resource "aws_cloudwatch_dashboard" "smartplant" {
  dashboard_name = "plantX-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", { stat = "Sum" }],
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            ["AWS/Lambda", "Errors", { stat = "Sum" }],
            ["AWS/Lambda", "Duration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "System Performance"
        }
      },
      {
        type = "log"
        properties = {
          query  = "fields @timestamp, @message | stats count() by @message"
          region = var.aws_region
          title  = "Error Logs"
        }
      }
    ]
  })
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "smartplant-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when Lambda has >5 errors in 5 min"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  alarm_name          = "smartplant-dynamodb-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Cost monitoring alarm
resource "aws_cloudwatch_metric_alarm" "daily_cost" {
  alarm_name          = "smartplant-daily-cost-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.alerts.arn]
}