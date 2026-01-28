#!/bin/bash

# Integration Test Runner
# Executes all integration tests for the DevOps Practice Environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${ENVIRONMENT:-dev}
TEST_DIR="$(dirname "$0")"
LOG_DIR="$TEST_DIR/logs"
REPORT_FILE="$LOG_DIR/integration-test-report-$(date +%Y%m%d_%H%M%S).html"

# Create log directory
mkdir -p "$LOG_DIR"

# Test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_suite() {
    echo -e "${YELLOW}Running Test Suite: $1${NC}"
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    PASSED_SUITES=$((PASSED_SUITES + 1))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    FAILED_SUITES=$((FAILED_SUITES + 1))
}

# Wait for system to be ready
wait_for_system() {
    print_header "Waiting for System to be Ready"
    
    echo "Checking if Docker Compose services are running..."
    if ! docker-compose -f docker-compose.yml ps | grep -q "Up"; then
        echo "Starting Docker Compose services..."
        docker-compose -f docker-compose.yml up -d
        sleep 30
    fi
    
    # Wait for key services
    services=(
        "http://localhost:4000/health:API Gateway"
        "http://localhost:3000:Frontend"
        "http://localhost:80/health:Load Balancer"
        "http://localhost:9090/-/ready:Prometheus"
        "http://localhost:3001/api/health:Grafana"
    )
    
    for service in "${services[@]}"; do
        url=$(echo "$service" | cut -d':' -f1-2)
        name=$(echo "$service" | cut -d':' -f3)
        
        echo "Waiting for $name to be ready..."
        max_attempts=30
        attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s -f "$url" > /dev/null 2>&1; then
                echo "✓ $name is ready"
                break
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                echo "⚠ $name failed to start within timeout, continuing anyway..."
                break
            fi
            
            sleep 5
            attempt=$((attempt + 1))
        done
    done
    
    echo "System readiness check completed"
}

# Run individual test suite
run_test_suite() {
    local test_script=$1
    local suite_name=$2
    
    print_suite "$suite_name"
    
    if [ ! -f "$test_script" ]; then
        print_error "$suite_name - Test script not found: $test_script"
        return 1
    fi
    
    # Make script executable
    chmod +x "$test_script"
    
    # Run the test suite
    if "$test_script"; then
        print_success "$suite_name - All tests passed"
        return 0
    else
        print_error "$suite_name - Some tests failed"
        return 1
    fi
}

# Generate HTML report
generate_html_report() {
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevOps Practice Environment - Integration Test Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
        }
        .header h1 {
            color: #2c3e50;
            margin-bottom: 10px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            padding: 20px;
            border-radius: 6px;
            text-align: center;
            color: white;
            font-weight: bold;
        }
        .total { background-color: #3498db; }
        .passed { background-color: #27ae60; }
        .failed { background-color: #e74c3c; }
        .test-suite {
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: 6px;
            overflow: hidden;
        }
        .suite-header {
            background-color: #34495e;
            color: white;
            padding: 15px;
            font-weight: bold;
        }
        .suite-content {
            padding: 15px;
        }
        .status-passed {
            color: #27ae60;
            font-weight: bold;
        }
        .status-failed {
            color: #e74c3c;
            font-weight: bold;
        }
        .log-section {
            margin-top: 20px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 6px;
            border-left: 4px solid #007bff;
        }
        .timestamp {
            color: #6c757d;
            font-size: 0.9em;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            text-align: center;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>DevOps Practice Environment</h1>
            <h2>Integration Test Report</h2>
            <p class="timestamp">Generated on $(date '+%Y-%m-%d %H:%M:%S')</p>
            <p>Environment: <strong>$ENVIRONMENT</strong></p>
        </div>
        
        <div class="summary">
            <div class="summary-card total">
                <h3>Total Suites</h3>
                <p style="font-size: 2em; margin: 0;">$TOTAL_SUITES</p>
            </div>
            <div class="summary-card passed">
                <h3>Passed</h3>
                <p style="font-size: 2em; margin: 0;">$PASSED_SUITES</p>
            </div>
            <div class="summary-card failed">
                <h3>Failed</h3>
                <p style="font-size: 2em; margin: 0;">$FAILED_SUITES</p>
            </div>
        </div>
        
        <div class="test-suites">
EOF

    # Add test suite results
    suites=(
        "System Integration:system-integration-test.sh"
        "Authentication & Authorization:authentication-test.sh"
        "Load Balancer:load-balancer-test.sh"
    )
    
    for suite in "${suites[@]}"; do
        suite_name=$(echo "$suite" | cut -d':' -f1)
        script_name=$(echo "$suite" | cut -d':' -f2)
        log_file="$LOG_DIR/${script_name%.sh}-$(date +%Y%m%d)*.log"
        
        # Find the most recent log file
        latest_log=$(ls -t $log_file 2>/dev/null | head -1 || echo "")
        
        if [ -f "$latest_log" ]; then
            if grep -q "All.*tests passed successfully" "$latest_log"; then
                status="passed"
                status_text="PASSED"
            else
                status="failed"
                status_text="FAILED"
            fi
            
            cat >> "$REPORT_FILE" << EOF
            <div class="test-suite">
                <div class="suite-header">
                    $suite_name
                    <span class="status-$status" style="float: right;">$status_text</span>
                </div>
                <div class="suite-content">
                    <p><strong>Log File:</strong> $(basename "$latest_log")</p>
                    <div class="log-section">
                        <h4>Test Summary:</h4>
                        <pre>$(tail -20 "$latest_log" | head -10)</pre>
                    </div>
                </div>
            </div>
EOF
        else
            cat >> "$REPORT_FILE" << EOF
            <div class="test-suite">
                <div class="suite-header">
                    $suite_name
                    <span class="status-failed" style="float: right;">NOT RUN</span>
                </div>
                <div class="suite-content">
                    <p>No log file found for this test suite.</p>
                </div>
            </div>
EOF
        fi
    done
    
    cat >> "$REPORT_FILE" << EOF
        </div>
        
        <div class="footer">
            <p>DevOps Practice Environment Integration Tests</p>
            <p>For detailed logs, check the files in the logs directory</p>
        </div>
    </div>
</body>
</html>
EOF

    echo "HTML report generated: $REPORT_FILE"
}

# Main execution
main() {
    print_header "DevOps Practice Environment - Integration Test Runner"
    echo "Environment: $ENVIRONMENT"
    echo "Test Directory: $TEST_DIR"
    echo "Log Directory: $LOG_DIR"
    echo ""
    
    # Wait for system to be ready
    wait_for_system
    
    echo ""
    print_header "Running Integration Test Suites"
    
    # Run all test suites
    run_test_suite "$TEST_DIR/system-integration-test.sh" "System Integration Tests"
    run_test_suite "$TEST_DIR/authentication-test.sh" "Authentication & Authorization Tests"
    run_test_suite "$TEST_DIR/load-balancer-test.sh" "Load Balancer Tests"
    
    echo ""
    print_header "Test Execution Summary"
    echo -e "${BLUE}Total Test Suites: $TOTAL_SUITES${NC}"
    echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
    echo -e "${RED}Failed: $FAILED_SUITES${NC}"
    
    # Generate HTML report
    generate_html_report
    
    if [ $FAILED_SUITES -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 All integration test suites passed successfully!${NC}"
        echo -e "${GREEN}The DevOps Practice Environment is ready for use.${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Some integration test suites failed.${NC}"
        echo -e "${YELLOW}Check the individual test logs in $LOG_DIR for details.${NC}"
        echo -e "${YELLOW}HTML report available at: $REPORT_FILE${NC}"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --system       Run only system integration tests"
        echo "  --auth         Run only authentication tests"
        echo "  --lb           Run only load balancer tests"
        echo ""
        echo "Environment Variables:"
        echo "  ENVIRONMENT    Set environment (default: dev)"
        echo ""
        exit 0
        ;;
    --system)
        run_test_suite "$TEST_DIR/system-integration-test.sh" "System Integration Tests"
        exit $?
        ;;
    --auth)
        run_test_suite "$TEST_DIR/authentication-test.sh" "Authentication & Authorization Tests"
        exit $?
        ;;
    --lb)
        run_test_suite "$TEST_DIR/load-balancer-test.sh" "Load Balancer Tests"
        exit $?
        ;;
    *)
        main "$@"
        ;;
esac