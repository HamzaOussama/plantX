
resource "aws_sns_topic" "alerts" {
  name = "plantX-alerts-${var.environment}"
  
  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_policy" "alerts_policy" {
  arn = aws_sns_topic.alerts.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "iot.amazonaws.com" }
      Action = "SNS:Publish"
      Resource = aws_sns_topic.alerts.arn
    },
    {
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "SNS:Publish"
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}

# DLQ for failed alerts
resource "aws_sqs_queue" "alerts_dlq" {
  name = "palntX-alerts-dlq-${var.environment}"
}

resource "aws_sns_topic_subscription" "alerts_dlq" {
  topic_arn            = aws_sns_topic.alerts.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.alerts_dlq.arn
  redrive_policy       = jsonencode({ deadLetterTargetArn = aws_sqs_queue.alerts_dlq.arn })
}