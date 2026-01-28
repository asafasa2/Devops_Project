# Nginx Load Balancer Configuration

This directory contains the Nginx load balancer configuration for the DevOps Practice Environment. The load balancer provides traffic distribution, health checks, and failover capabilities for all microservices.

## Configuration Files

### Main Configuration Files

- **`nginx.conf`** - Base configuration with load balancing and health checks
- **`nginx.dev.conf`** - Development-specific configuration (simplified)
- **`nginx.prod.conf`** - Production configuration with SSL, caching, and enhanced security

### SSL Configuration

- **`ssl/`** - Directory for SSL certificates and keys
- **`ssl/ssl-params.conf`** - Nginx SSL configuration snippet (auto-generated)

## Features

### Load Balancing

- **Algorithm**: `least_conn` - Routes requests to the server with the least active connections
- **Health Checks**: Automatic health monitoring with configurable fail thresholds
- **Failover**: Automatic failover to healthy upstream servers
- **Session Persistence**: Configurable session affinity (disabled by default)

### Upstream Services

The load balancer routes traffic to the following services:

| Service | Port | Health Check | Max Fails | Fail Timeout |
|---------|------|--------------|-----------|--------------|
| Frontend | 3000 | HTTP | 3 | 30s |
| API Gateway | 4000 | HTTP | 3 | 30s |
| Learning Service | 4001 | HTTP | 3 | 30s |
| User Service | 4002 | HTTP | 3 | 30s |
| Lab Service | 4003 | HTTP | 2 | 60s |
| Assessment Service | 4004 | HTTP | 3 | 30s |

### URL Routing

- **`/`** - Frontend application
- **`/api/`** - API Gateway (main API endpoint)
- **`/api/learning/`** - Learning Service (direct access)
- **`/api/users/`** - User Service (direct access)
- **`/api/labs/`** - Lab Service (direct access)
- **`/api/assessments/`** - Assessment Service (direct access)
- **`/api/labs/ws/`** - WebSocket support for lab terminals

### Health Check Endpoints

- **`/health`** - Basic load balancer health check
- **`/health/detailed`** - Detailed health status with upstream information
- **`/nginx_status`** - Nginx status and metrics (restricted access)
- **`/health/{service}`** - Individual service health checks

### Security Features

- **Rate Limiting**: Configurable rate limits for API and login endpoints
- **Security Headers**: X-Frame-Options, X-XSS-Protection, X-Content-Type-Options, etc.
- **SSL/TLS**: Full SSL support with modern cipher suites (production)
- **Request Filtering**: Basic request validation and filtering

### Performance Features

- **Connection Pooling**: Persistent connections to upstream servers
- **Compression**: Gzip compression for text-based responses
- **Caching**: Static file caching and optional API response caching
- **Keep-Alive**: HTTP keep-alive for improved performance

## Usage

### Development Environment

```bash
# Use development configuration
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up nginx
```

### Production Environment

```bash
# Use production configuration with SSL
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up nginx
```

### Generate SSL Certificates

```bash
# Generate self-signed certificates for development
./scripts/generate-ssl-certs.sh

# Generate certificates for specific domain
./scripts/generate-ssl-certs.sh --domain example.com
```

### Test Load Balancer

```bash
# Run comprehensive load balancer tests
./scripts/test-load-balancer.sh

# Run specific test categories
./scripts/test-load-balancer.sh health
./scripts/test-load-balancer.sh routing
./scripts/test-load-balancer.sh balancing
```

## Configuration Customization

### Environment Variables

The following environment variables can be used to customize the load balancer:

- **`NGINX_PORT`** - HTTP port (default: 80)
- **`NGINX_HTTPS_PORT`** - HTTPS port (default: 443)
- **`DOMAIN_NAME`** - Domain name for SSL certificates
- **`RATE_LIMIT_API`** - API rate limit (default: 20r/s)
- **`RATE_LIMIT_LOGIN`** - Login rate limit (default: 5r/m)

### Adding New Services

To add a new service to the load balancer:

1. **Add upstream definition**:
```nginx
upstream new_service_servers {
    least_conn;
    server new-service:4005 max_fails=3 fail_timeout=30s weight=1;
    keepalive 32;
}
```

2. **Add location block**:
```nginx
location /api/new-service/ {
    proxy_pass http://new_service_servers/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_next_upstream_tries 2;
    proxy_next_upstream_timeout 60s;
}
```

3. **Add health check endpoint**:
```nginx
location /health/new-service {
    access_log off;
    proxy_pass http://new_service_servers/health;
    proxy_connect_timeout 5s;
    proxy_read_timeout 5s;
}
```

### Scaling Services

To add multiple replicas of a service:

```nginx
upstream api_servers {
    least_conn;
    server api-gateway-1:4000 max_fails=3 fail_timeout=30s weight=1;
    server api-gateway-2:4000 max_fails=3 fail_timeout=30s weight=1;
    server api-gateway-3:4000 max_fails=3 fail_timeout=30s weight=1;
    keepalive 32;
}
```

## Monitoring and Troubleshooting

### Log Files

- **Access Log**: `/var/log/nginx/access.log`
- **Error Log**: `/var/log/nginx/error.log`
- **Health Check Log**: `/var/log/nginx/health.log`

### Monitoring Endpoints

- **Nginx Status**: `http://localhost:8090/nginx_status`
- **Health Check**: `http://localhost/health`
- **Detailed Health**: `http://localhost:8090/health/detailed`

### Common Issues

1. **Upstream server not responding**:
   - Check service health: `curl http://localhost:8090/health/{service}`
   - Verify service is running: `docker ps`
   - Check service logs: `docker logs {service-container}`

2. **SSL certificate issues**:
   - Regenerate certificates: `./scripts/generate-ssl-certs.sh`
   - Check certificate validity: `openssl x509 -in nginx/ssl/cert.pem -text -noout`

3. **Rate limiting triggered**:
   - Check rate limit configuration in nginx.conf
   - Monitor access logs for 429 responses
   - Adjust rate limits if necessary

4. **Load balancing not working**:
   - Verify upstream configuration
   - Check upstream server health
   - Review nginx error logs

## Performance Tuning

### Worker Configuration

```nginx
worker_processes auto;
worker_connections 2048;
worker_rlimit_nofile 4096;
```

### Buffer Settings

```nginx
client_body_buffer_size 128k;
client_header_buffer_size 1k;
large_client_header_buffers 4 4k;
```

### Keepalive Settings

```nginx
keepalive_timeout 65;
keepalive_requests 1000;
```

### Upstream Keepalive

```nginx
upstream backend {
    server backend1:8080;
    keepalive 32;
    keepalive_requests 100;
    keepalive_timeout 60s;
}
```

## Security Considerations

- Use strong SSL/TLS configuration in production
- Implement proper rate limiting for public endpoints
- Configure security headers appropriately
- Restrict access to monitoring endpoints
- Regularly update nginx and monitor security advisories
- Use proper firewall rules to restrict access
- Implement proper logging and monitoring

## References

- [Nginx Load Balancing Documentation](https://nginx.org/en/docs/http/load_balancing.html)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Nginx Rate Limiting](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html)
- [Nginx Health Checks](https://nginx.org/en/docs/http/ngx_http_upstream_module.html#health_check)