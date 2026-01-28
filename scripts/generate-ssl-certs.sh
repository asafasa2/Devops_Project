#!/bin/bash

# SSL Certificate Generation Script for DevOps Practice Environment
# Generates self-signed certificates for development and testing

set -e

# Configuration
SSL_DIR="${SSL_DIR:-./nginx/ssl}"
DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
CERT_DAYS="${CERT_DAYS:-365}"
KEY_SIZE="${KEY_SIZE:-2048}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if OpenSSL is available
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL is not installed or not in PATH"
        exit 1
    fi
    
    log_info "OpenSSL version: $(openssl version)"
}

# Create SSL directory if it doesn't exist
create_ssl_directory() {
    if [ ! -d "$SSL_DIR" ]; then
        log_info "Creating SSL directory: $SSL_DIR"
        mkdir -p "$SSL_DIR"
    fi
}

# Generate private key
generate_private_key() {
    local key_file="$SSL_DIR/key.pem"
    
    if [ -f "$key_file" ]; then
        log_warning "Private key already exists: $key_file"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping private key generation"
            return 0
        fi
    fi
    
    log_info "Generating private key ($KEY_SIZE bits)..."
    openssl genrsa -out "$key_file" "$KEY_SIZE"
    chmod 600 "$key_file"
    log_success "Private key generated: $key_file"
}

# Generate certificate signing request
generate_csr() {
    local csr_file="$SSL_DIR/cert.csr"
    local key_file="$SSL_DIR/key.pem"
    
    log_info "Generating certificate signing request..."
    
    # Create OpenSSL config for CSR
    local config_file="$SSL_DIR/openssl.conf"
    cat > "$config_file" << EOF
[req]
default_bits = $KEY_SIZE
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=Development
L=DevOps
O=DevOps Practice Environment
OU=IT Department
CN=$DOMAIN_NAME

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN_NAME
DNS.2 = localhost
DNS.3 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF
    
    openssl req -new -key "$key_file" -out "$csr_file" -config "$config_file"
    log_success "Certificate signing request generated: $csr_file"
}

# Generate self-signed certificate
generate_certificate() {
    local cert_file="$SSL_DIR/cert.pem"
    local csr_file="$SSL_DIR/cert.csr"
    local key_file="$SSL_DIR/key.pem"
    local config_file="$SSL_DIR/openssl.conf"
    
    if [ -f "$cert_file" ]; then
        log_warning "Certificate already exists: $cert_file"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping certificate generation"
            return 0
        fi
    fi
    
    log_info "Generating self-signed certificate (valid for $CERT_DAYS days)..."
    
    openssl x509 -req -in "$csr_file" -signkey "$key_file" -out "$cert_file" \
        -days "$CERT_DAYS" -extensions v3_req -extfile "$config_file"
    
    chmod 644 "$cert_file"
    log_success "Self-signed certificate generated: $cert_file"
}

# Generate DH parameters for enhanced security
generate_dhparam() {
    local dhparam_file="$SSL_DIR/dhparam.pem"
    
    if [ -f "$dhparam_file" ]; then
        log_info "DH parameters already exist: $dhparam_file"
        return 0
    fi
    
    log_info "Generating DH parameters (this may take a while)..."
    openssl dhparam -out "$dhparam_file" 2048
    chmod 644 "$dhparam_file"
    log_success "DH parameters generated: $dhparam_file"
}

# Verify generated certificates
verify_certificates() {
    local cert_file="$SSL_DIR/cert.pem"
    local key_file="$SSL_DIR/key.pem"
    
    log_info "Verifying generated certificates..."
    
    # Check certificate validity
    if openssl x509 -in "$cert_file" -text -noout > /dev/null 2>&1; then
        log_success "Certificate is valid"
        
        # Show certificate details
        log_info "Certificate details:"
        echo "  Subject: $(openssl x509 -in "$cert_file" -subject -noout | sed 's/subject=//')"
        echo "  Issuer: $(openssl x509 -in "$cert_file" -issuer -noout | sed 's/issuer=//')"
        echo "  Valid from: $(openssl x509 -in "$cert_file" -startdate -noout | sed 's/notBefore=//')"
        echo "  Valid until: $(openssl x509 -in "$cert_file" -enddate -noout | sed 's/notAfter=//')"
        echo "  Serial: $(openssl x509 -in "$cert_file" -serial -noout | sed 's/serial=//')"
    else
        log_error "Certificate verification failed"
        return 1
    fi
    
    # Check private key
    if openssl rsa -in "$key_file" -check -noout > /dev/null 2>&1; then
        log_success "Private key is valid"
    else
        log_error "Private key verification failed"
        return 1
    fi
    
    # Check if certificate and key match
    local cert_modulus=$(openssl x509 -noout -modulus -in "$cert_file" | openssl md5)
    local key_modulus=$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)
    
    if [ "$cert_modulus" = "$key_modulus" ]; then
        log_success "Certificate and private key match"
    else
        log_error "Certificate and private key do not match"
        return 1
    fi
}

# Create nginx SSL configuration snippet
create_nginx_ssl_config() {
    local ssl_config_file="$SSL_DIR/ssl-params.conf"
    
    log_info "Creating nginx SSL configuration snippet..."
    
    cat > "$ssl_config_file" << 'EOF'
# SSL Configuration for Nginx
# Include this file in your nginx server block with: include /etc/nginx/ssl/ssl-params.conf;

# SSL Certificate and Key
ssl_certificate /etc/nginx/ssl/cert.pem;
ssl_certificate_key /etc/nginx/ssl/key.pem;

# SSL Session Configuration
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# SSL Protocols and Ciphers
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
ssl_prefer_server_ciphers on;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;

# Security Headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# DH Parameters (uncomment if dhparam.pem exists)
# ssl_dhparam /etc/nginx/ssl/dhparam.pem;
EOF
    
    log_success "Nginx SSL configuration created: $ssl_config_file"
}

# Cleanup temporary files
cleanup() {
    local csr_file="$SSL_DIR/cert.csr"
    local config_file="$SSL_DIR/openssl.conf"
    
    log_info "Cleaning up temporary files..."
    rm -f "$csr_file" "$config_file"
    log_success "Cleanup completed"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generate SSL certificates for the DevOps Practice Environment"
    echo ""
    echo "Options:"
    echo "  -d, --domain DOMAIN    Domain name for certificate (default: localhost)"
    echo "  -o, --output DIR       Output directory for certificates (default: ./nginx/ssl)"
    echo "  --days DAYS           Certificate validity in days (default: 365)"
    echo "  --key-size SIZE       Private key size in bits (default: 2048)"
    echo "  --skip-dhparam        Skip DH parameters generation"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  SSL_DIR               Output directory (default: ./nginx/ssl)"
    echo "  DOMAIN_NAME           Domain name (default: localhost)"
    echo "  CERT_DAYS             Certificate validity (default: 365)"
    echo "  KEY_SIZE              Private key size (default: 2048)"
}

# Main function
main() {
    local skip_dhparam=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                DOMAIN_NAME="$2"
                shift 2
                ;;
            -o|--output)
                SSL_DIR="$2"
                shift 2
                ;;
            --days)
                CERT_DAYS="$2"
                shift 2
                ;;
            --key-size)
                KEY_SIZE="$2"
                shift 2
                ;;
            --skip-dhparam)
                skip_dhparam=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_info "Starting SSL certificate generation..."
    echo "Configuration:"
    echo "  Domain: $DOMAIN_NAME"
    echo "  Output Directory: $SSL_DIR"
    echo "  Certificate Validity: $CERT_DAYS days"
    echo "  Key Size: $KEY_SIZE bits"
    echo ""
    
    # Execute certificate generation steps
    check_openssl
    create_ssl_directory
    generate_private_key
    generate_csr
    generate_certificate
    
    if [ "$skip_dhparam" = false ]; then
        generate_dhparam
    fi
    
    verify_certificates
    create_nginx_ssl_config
    cleanup
    
    echo ""
    log_success "SSL certificate generation completed successfully!"
    echo ""
    echo "Generated files:"
    echo "  - Private Key: $SSL_DIR/key.pem"
    echo "  - Certificate: $SSL_DIR/cert.pem"
    echo "  - Nginx Config: $SSL_DIR/ssl-params.conf"
    if [ "$skip_dhparam" = false ]; then
        echo "  - DH Parameters: $SSL_DIR/dhparam.pem"
    fi
    echo ""
    echo "To use these certificates with nginx:"
    echo "1. Mount the SSL directory in your nginx container"
    echo "2. Include the SSL configuration in your server block"
    echo "3. Update your nginx configuration to use HTTPS"
    echo ""
    log_warning "Note: These are self-signed certificates for development use only."
    log_warning "For production, use certificates from a trusted Certificate Authority."
}

# Run main function
main "$@"