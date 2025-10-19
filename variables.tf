/**
 * SmartPlant Guardian - Terraform Variables (DEV Only)
 */

# -----------------------------
# Environment
# -----------------------------
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# -----------------------------
# IoT Core
# -----------------------------
variable "iot_device_count" {
  description = "Expected number of IoT devices"
  type        = number
  default     = 1
}

variable "iot_mqtt_port" {
  description = "MQTT port"
  type        = number
  default     = 8883
}

# -----------------------------
# DynamoDB
# -----------------------------
variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity"
  type        = number
  default     = 5
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "sensor_data_retention_days" {
  description = "Days to retain sensor data"
  type        = number
  default     = 90
}

# -----------------------------
# Lambda
# -----------------------------
variable "lambda_memory" {
  description = "Lambda memory allocation (MB)"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout (seconds)"
  type        = number
  default     = 30
}

# -----------------------------
# Alerts
# -----------------------------
variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "alert_phone" {
  description = "Phone number for SMS alerts (E.164)"
  type        = string
  default     = ""
}

variable "low_moisture_threshold" {
  description = "Soil moisture threshold (%)"
  type        = number
  default     = 30
}

variable "high_temperature_threshold" {
  description = "High temperature threshold (°C)"
  type        = number
  default     = 35
}

variable "low_temperature_threshold" {
  description = "Low temperature threshold (°C)"
  type        = number
  default     = 10
}

# -----------------------------
# S3 Data Lake
# -----------------------------
variable "s3_enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "s3_archive_after_days" {
  description = "Days before archiving to Glacier"
  type        = number
  default     = 30
}

variable "s3_delete_after_days" {
  description = "Days before deleting from S3"
  type        = number
  default     = 365
}

# -----------------------------
# CloudWatch
# -----------------------------
variable "log_retention_days" {
  description = "CloudWatch log retention (days)"
  type        = number
  default     = 14
}

variable "enable_enhanced_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

# -----------------------------
# Cost & Deployment
# -----------------------------
variable "enable_cost_tracking" {
  description = "Enable AWS Budgets"
  type        = bool
  default     = true
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit (USD)"
  type        = number
  default     = 50
}

# -----------------------------
# Backup & Recovery (DEV only: disabled)
# -----------------------------
variable "enable_backup" {
  description = "Enable DynamoDB backups"
  type        = bool
  default     = false
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery for DynamoDB"
  type        = bool
  default     = false
}

variable "enable_auto_recovery" {
  description = "Enable automatic recovery for failed resources"
  type        = bool
  default     = false
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backups"
  type        = bool
  default     = false
}

variable "multi_region_enabled" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = false
}

variable "secondary_region" {
  description = "Secondary AWS region (for multi-region, if enabled)"
  type        = string
  default     = "us-west-2"
}

# -----------------------------
# Tags
# -----------------------------
variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "engineering"
}

variable "owner" {
  description = "Owner of resources"
  type        = string
  default     = "DevOps"
}

# -----------------------------
# Locals (computed)
# -----------------------------
locals {
  is_production  = false
  is_development = true
}

variable "region" {
  
}