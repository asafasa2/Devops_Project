# Service module variables
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "network_id" {
  description = "Docker network ID for services"
  type        = string
}

variable "db_volume_name" {
  description = "Database volume name"
  type        = string
}