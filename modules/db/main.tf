# terraform/modules/dynamodb/main.tf

resource "aws_dynamodb_table" "sensor_readings" {
  name           = "plantX-sensor-readings-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"  # Auto-scales
  hash_key       = "device_id"
  range_key      = "timestamp"
  
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
  
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }
  
  tags = {
    Name = "smartplant-sensors"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "health_predictions" {
  name           = "plantX-health-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"
  range_key      = "timestamp"
  
  attribute {
    name = "device_id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "S"
  }
  
  tags = {
    Name = "plantX-health"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "alerts" {
  name           = "plantX-alerts-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "alert_id"
  range_key      = "timestamp"
  
  attribute {
    name = "alert_id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "S"
  }
  
  tags = {
    Name = "plantX-alerts"
    Environment = var.environment
  }
}