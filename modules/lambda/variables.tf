variable "aws_region" {
  type = string
}
variable "environment" {
  type = string
}
variable "health_table_name" {
  type = string
}
variable "sns_topic_arn" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}
variable "sensor_table_name" {
  type = string
}