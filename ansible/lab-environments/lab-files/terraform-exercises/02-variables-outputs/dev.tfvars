# Development Environment Configuration

environment = "dev"
app_name    = "myapp-dev"
app_port    = 8080
replicas    = 1
enable_monitoring = false

tags = {
  Environment = "development"
  Team        = "platform"
  CostCenter  = "engineering"
  Owner       = "dev-team"
}

container_config = {
  memory_limit = "256m"
  cpu_limit    = "0.25"
  restart      = "unless-stopped"
}