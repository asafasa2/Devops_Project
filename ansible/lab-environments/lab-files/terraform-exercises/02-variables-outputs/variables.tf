# Variables for Terraform Lab 2 - Template
# Complete the variable definitions below

# TODO: Define environment variable
# Requirements:
# - Type: string
# - Default: "dev"
# - Validation: must be one of "dev", "staging", "prod"
# - Description: "Environment name"

# TODO: Define app_name variable
# Requirements:
# - Type: string
# - Default: "webapp"
# - Description: "Application name"

# TODO: Define app_port variable
# Requirements:
# - Type: number
# - Default: 8080
# - Description: "Application port number"

# TODO: Define replicas variable
# Requirements:
# - Type: number
# - Default: 1
# - Validation: must be between 1 and 5
# - Description: "Number of application replicas"

# TODO: Define enable_monitoring variable
# Requirements:
# - Type: bool
# - Default: false
# - Description: "Enable monitoring stack"

# TODO: Define tags variable
# Requirements:
# - Type: map(string)
# - Default: {}
# - Description: "Tags to apply to all resources"