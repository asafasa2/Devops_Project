# Network module variables
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_subnet" {
  description = "Application network subnet"
  type        = string
  default     = "172.20.0.0/16"
}

variable "app_gateway" {
  description = "Application network gateway"
  type        = string
  default     = "172.20.0.1"
}

variable "monitoring_subnet" {
  description = "Monitoring network subnet"
  type        = string
  default     = "172.21.0.0/16"
}

variable "monitoring_gateway" {
  description = "Monitoring network gateway"
  type        = string
  default     = "172.21.0.1"
}

variable "db_subnet" {
  description = "Database network subnet"
  type        = string
  default     = "172.22.0.0/16"
}

variable "db_gateway" {
  description = "Database network gateway"
  type        = string
  default     = "172.22.0.1"
}