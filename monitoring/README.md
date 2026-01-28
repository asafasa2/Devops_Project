# DevOps Practice Environment - Monitoring Stack

This directory contains the complete monitoring and logging infrastructure for the DevOps Practice Environment, including Prometheus, Grafana, ELK stack, and related configurations.

## Architecture Overview

The monitoring stack consists of:

### Metrics Collection & Monitoring
- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization and dashboarding platform
- **Alertmanager**: Alert routing and notification management
- **Node Exporter**: System metrics collection
- **cAdvisor**: Container metrics collection
- **Database Exporters**: PostgreSQL and Redis metrics

### Logging & Analysis
- **Elasticsearch**: Log storage and search engine
- **Logstash**: Log processing and transformation
- **Kibana**: Log visualization and analysis
- **Filebeat**: Log collection agent

## Quick Start

1. **Start the monitoring stack:**
   ```bash
   ./monitoring/scripts/setup-monitoring.sh
   ```

2. **Access the monitoring tools:**
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3001 (admin/admin123)
   - Alertmanager: http://localhost:9093
   - Elasticsearch: http://localhost:9200
   - Kibana: http://localhost:5601

## Configuration Files

### Prometheus Configuration
- `prometheus/prometheus.yml`: Main Prometheus configuration
- `prometheus/alert_rules.yml`: Alert rules for system and application monitoring

### Grafana Configuration
- `grafana/grafana.ini`: Grafana server configuration
- `grafana/provisioning/`: Datasources and dashboard provisioning
- `grafana/dashboards/`: Pre-built dashboards

### ELK Stack Configuration
- `elasticsearch/elasticsearch.yml`: Elasticsearch configuration
- `logstash/logstash.yml`: Logstash server configuration
- `logstash/pipeline/logstash.conf`: Log processing pipeline
- `kibana/kibana.yml`: Kibana configuration
- `filebeat/filebeat.yml`: Log collection configuration

## Pre-configured Dashboards

### Grafana Dashboards
1. **System Overview** (`system-overview`)
   - CPU and memory usage
   - Service health status
   - System performance metrics

2. **Learning Platform Metrics** (`learning-platform`)
   - HTTP request rates and response times
   - User activity and engagement
   - Quiz and lab session metrics
   - Application-specific KPIs

### Kibana Dashboards
- **DevOps Practice Logs Dashboard**: Centralized log analysis and search

## Alert Rules

The monitoring stack includes pre-configured alerts for:

### System Alerts
- High CPU usage (>80% for 5 minutes)
- High memory usage (>85% for 5 minutes)
- Low disk space (<20%)
- Service downtime

### Application Alerts
- High error rates (>5% for 5 minutes)
- High response times (>1 second 95th percentile)
- Database connectivity issues
- Lab session failures

### Learning Platform Specific Alerts
- Low user engagement
- High quiz failure rates
- Lab environment provisioning issues

## Metrics Collection

### Application Metrics
Services should expose metrics on the following endpoints:
- API Gateway: `http://api-gateway:4000/metrics`
- Learning Service: `http://learning-service:4001/metrics`
- User Service: `http://user-service:4002/metrics`
- Lab Service: `http://lab-service:4003/actuator/prometheus`
- Assessment Service: `http://assessment-service:4004/metrics`

### Custom Metrics
The platform collects custom metrics for:
- User registration and activity rates
- Quiz completion and success rates
- Lab session creation and completion
- Learning module progress
- System resource utilization

## Log Collection

### Log Sources
- **Container logs**: Automatically collected from all Docker containers
- **Application logs**: Structured JSON logs from microservices
- **Nginx logs**: Access and error logs from the load balancer
- **System logs**: Host system logs and events

### Log Processing
Logstash processes logs with:
- JSON parsing for structured logs
- Grok patterns for unstructured logs
- Field extraction and enrichment
- Log level classification
- Service identification

### Log Storage
- Logs are stored in Elasticsearch with daily indices
- Index pattern: `devops-practice-logs-YYYY.MM.dd`
- Retention: Configurable (default: 30 days)

## Troubleshooting

### Common Issues

1. **Elasticsearch fails to start**
   - Check available disk space
   - Verify memory limits (minimum 512MB)
   - Check file permissions on data directory

2. **Grafana dashboards not loading**
   - Verify Prometheus datasource connectivity
   - Check Grafana logs for errors
   - Ensure dashboard files are properly mounted

3. **No logs in Kibana**
   - Verify Filebeat is collecting logs
   - Check Logstash processing pipeline
   - Ensure Elasticsearch is receiving data

4. **Alerts not firing**
   - Check Prometheus alert rules syntax
   - Verify Alertmanager configuration
   - Test notification channels

### Health Checks

All monitoring services include health checks:
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs prometheus
docker-compose logs grafana
docker-compose logs elasticsearch
docker-compose logs kibana
```

### Performance Tuning

For production environments, consider:
- Increasing Elasticsearch heap size
- Adjusting Prometheus retention period
- Optimizing Logstash pipeline workers
- Configuring Grafana caching

## Security Considerations

- Default passwords should be changed in production
- Enable authentication for all services
- Use TLS/SSL for external access
- Implement network segmentation
- Regular security updates for all components

## Maintenance

### Regular Tasks
- Monitor disk usage for log storage
- Review and update alert thresholds
- Clean up old indices and metrics
- Update dashboard configurations
- Backup Grafana dashboards and Elasticsearch indices

### Scaling
- Add more Elasticsearch nodes for high log volumes
- Use Prometheus federation for multiple environments
- Implement log rotation and archival policies
- Consider using managed services for production

## Integration with CI/CD

The monitoring stack integrates with the CI/CD pipeline to:
- Monitor deployment health
- Track deployment metrics
- Alert on deployment failures
- Provide rollback triggers based on metrics

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review service logs for error messages
3. Consult the official documentation for each component
4. Check the project's issue tracker for known problems