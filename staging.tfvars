# SmartPlant Guardian - Staging Environment
# For testing before production deployment

aws_region  = "us-east-1"
environment = "staging"

# ============================================================================
# IoT Core - Staging
# ============================================================================
iot_device_count = 10   # Test with multiple devices
iot_mqtt_port    = 8883 # Secure MQTT

# ============================================================================
# DynamoDB - Staging (Moderate)
# ============================================================================
dynamodb_billing_mode      = "PAY_PER_REQUEST" # Auto-scales
dynamodb_read_capacity     = 10                # Moderate capacity
dynamodb_write_capacity    = 10
sensor_data_retention_days = 60 # Keep 2 months of data

# ============================================================================
# Lambda - Staging
# ============================================================================
lambda_memory  = 512 # Higher memory for better performance
lambda_timeout = 45  # 45 seconds

# ============================================================================
# Alerting - Staging
# ============================================================================
alert_email                = "h.oussama.alg@gmail.com" # CHANGE THIS
alert_phone                = "+1234567890"             # Test phone
low_moisture_threshold     = 30
high_temperature_threshold = 35
low_temperature_threshold  = 10

# ============================================================================
# S3 Data Lake - Staging
# ============================================================================
s3_enable_versioning  = true # Enable versioning
s3_archive_after_days = 14   # Archive after 2 weeks
s3_delete_after_days  = 90   # Keep 3 months

# ============================================================================
# CloudWatch - Staging
# ============================================================================
log_retention_days         = 14   # Keep logs for 2 weeks
enable_enhanced_monitoring = true # Enhanced metrics for testing

# ============================================================================
# Cost Control - Staging
# ============================================================================
enable_cost_tracking = true # Track costs
monthly_budget_limit = 30   # $30/month limit

# ============================================================================
# Backup & Disaster Recovery - Staging
# ============================================================================
enable_backup = true # Enable backups
enable_pitr   = true # Point-in-time recovery

# ============================================================================
# Tagging
# ============================================================================
additional_tags = {
  Team       = "QA"
  CostCenter = "Testing"
  Project    = "SmartPlant"
}
cost_center = "testing"
owner       = "QA Team"

# ============================================================================
# Deployment - Staging
# ============================================================================
enable_auto_recovery       = true  # Auto-recovery for stability testing
enable_cross_region_backup = false # Single region for staging
multi_region_enabled       = false # Single region

region = "us-east-01"