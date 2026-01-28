# Variables for Terraform Lab 2 - Complete Solution

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "webapp"
}

variable "app_port" {
  description = "Application port number"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.app_port >= 1024 && var.app_port <= 65535
    error_message = "App port must be between 1024 and 65535."
  }
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 1
  
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 5
    error_message = "Replicas must be between 1 and 5."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "container_config" {
  description = "Advanced container configuration"
  type = object({
    memory_limit = optional(string, "512m")
    cpu_limit    = optional(string, "0.5")
    restart      = optional(string, "unless-stopped")
  })
  default = {}
}