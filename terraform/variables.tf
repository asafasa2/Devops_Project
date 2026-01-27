# Variables for multi-environment configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
  
  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 10
    error_message = "App replicas must be between 1 and 10."
  }
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "devops_practice_2024"
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack (ELK)"
  type        = bool
  default     = true
}