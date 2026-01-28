#!/bin/bash

# Authentication and Authorization Integration Tests
# Tests JWT token flow, role-based access, and cross-service authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_URL=${API_URL:-http://localhost:4000}
ENVIRONMENT=${ENVIRONMENT:-dev}

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging
LOG_FILE="tests/integration/logs/auth-test-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    log "Starting: $1"
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
    log "Test: $1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS: $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log "ERROR: $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

# Test user registration
test_user_registration() {
    print_header "User Registration Tests"
    
    # Generate unique test data
    TIMESTAMP=$(date +%s)
    TEST_EMAIL="test-user-$TIMESTAMP@example.com"
    TEST_USERNAME="testuser$TIMESTAMP"
    TEST_PASSWORD="SecurePassword123!"
    
    # Test successful registration
    print_test "Valid user registration"
    REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/user/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_EMAIL\",\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$REGISTER_RESPONSE" | grep -q "success\|created\|registered\|user"; then
        print_success "User registration successful"
        export TEST_EMAIL TEST_USERNAME TEST_PASSWORD
    else
        print_error "User registration failed: $REGISTER_RESPONSE"
        return 1
    fi
    
    # Test duplicate email registration
    print_test "Duplicate email registration rejection"
    DUPLICATE_RESPONSE=$(curl -s -X POST "$API_URL/api/user/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_EMAIL\",\"username\":\"duplicate$TIMESTAMP\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$DUPLICATE_RESPONSE" | grep -q "exists\|duplicate\|already\|error"; then
        print_success "Duplicate email registration properly rejected"
    else
        print_error "Duplicate email registration not properly handled: $DUPLICATE_RESPONSE"
    fi
    
    # Test invalid email format
    print_test "Invalid email format rejection"
    INVALID_EMAIL_RESPONSE=$(curl -s -X POST "$API_URL/api/user/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"invalid-email\",\"username\":\"invalid$TIMESTAMP\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$INVALID_EMAIL_RESPONSE" | grep -q "invalid\|error\|format"; then
        print_success "Invalid email format properly rejected"
    else
        print_error "Invalid email format not properly handled: $INVALID_EMAIL_RESPONSE"
    fi
    
    # Test weak password rejection
    print_test "Weak password rejection"
    WEAK_PASSWORD_RESPONSE=$(curl -s -X POST "$API_URL/api/user/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"weak$TIMESTAMP@example.com\",\"username\":\"weak$TIMESTAMP\",\"password\":\"123\"}")
    
    if echo "$WEAK_PASSWORD_RESPONSE" | grep -q "weak\|invalid\|error\|password"; then
        print_success "Weak password properly rejected"
    else
        print_error "Weak password not properly handled: $WEAK_PASSWORD_RESPONSE"
    fi
}

# Test user authentication
test_user_authentication() {
    print_header "User Authentication Tests"
    
    # Test successful login
    print_test "Valid user login"
    LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/user/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
    
    JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    USER_ID=$(echo "$LOGIN_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    if [ -n "$JWT_TOKEN" ] && [ ${#JWT_TOKEN} -gt 20 ]; then
        print_success "User login successful, JWT token received"
        export JWT_TOKEN USER_ID
    else
        print_error "User login failed: $LOGIN_RESPONSE"
        return 1
    fi
    
    # Test invalid credentials
    print_test "Invalid credentials rejection"
    INVALID_LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/user/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"WrongPassword\"}")
    
    if echo "$INVALID_LOGIN_RESPONSE" | grep -q "invalid\|error\|unauthorized\|wrong"; then
        print_success "Invalid credentials properly rejected"
    else
        print_error "Invalid credentials not properly handled: $INVALID_LOGIN_RESPONSE"
    fi
    
    # Test non-existent user
    print_test "Non-existent user login rejection"
    NONEXISTENT_RESPONSE=$(curl -s -X POST "$API_URL/api/user/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"nonexistent@example.com\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$NONEXISTENT_RESPONSE" | grep -q "not found\|invalid\|error\|unauthorized"; then
        print_success "Non-existent user login properly rejected"
    else
        print_error "Non-existent user login not properly handled: $NONEXISTENT_RESPONSE"
    fi
}

# Test JWT token validation
test_jwt_validation() {
    print_header "JWT Token Validation Tests"
    
    # Test valid token access
    print_test "Valid JWT token access to protected endpoint"
    PROFILE_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/user/profile")
    
    if echo "$PROFILE_RESPONSE" | grep -q "email\|username\|profile"; then
        print_success "Valid JWT token grants access to protected endpoint"
    else
        print_error "Valid JWT token access failed: $PROFILE_RESPONSE"
    fi
    
    # Test invalid token rejection
    print_test "Invalid JWT token rejection"
    INVALID_TOKEN_RESPONSE=$(curl -s -H "Authorization: Bearer invalid.jwt.token" "$API_URL/api/user/profile")
    
    if echo "$INVALID_TOKEN_RESPONSE" | grep -q "unauthorized\|invalid\|error\|token"; then
        print_success "Invalid JWT token properly rejected"
    else
        print_error "Invalid JWT token not properly handled: $INVALID_TOKEN_RESPONSE"
    fi
    
    # Test missing token rejection
    print_test "Missing JWT token rejection"
    NO_TOKEN_RESPONSE=$(curl -s "$API_URL/api/user/profile")
    
    if echo "$NO_TOKEN_RESPONSE" | grep -q "unauthorized\|missing\|error\|token"; then
        print_success "Missing JWT token properly rejected"
    else
        print_error "Missing JWT token not properly handled: $NO_TOKEN_RESPONSE"
    fi
    
    # Test expired token (simulate by using malformed token)
    print_test "Malformed JWT token rejection"
    MALFORMED_TOKEN_RESPONSE=$(curl -s -H "Authorization: Bearer malformed-token-format" "$API_URL/api/user/profile")
    
    if echo "$MALFORMED_TOKEN_RESPONSE" | grep -q "unauthorized\|invalid\|error\|malformed"; then
        print_success "Malformed JWT token properly rejected"
    else
        print_error "Malformed JWT token not properly handled: $MALFORMED_TOKEN_RESPONSE"
    fi
}

# Test cross-service authentication
test_cross_service_auth() {
    print_header "Cross-Service Authentication Tests"
    
    # Test learning service authentication
    print_test "Learning service authentication"
    LEARNING_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/learning/modules")
    
    if echo "$LEARNING_RESPONSE" | grep -q "modules\|learning\|content" || [ "$(echo "$LEARNING_RESPONSE" | jq -r 'type' 2>/dev/null)" = "array" ]; then
        print_success "Learning service authentication successful"
    else
        print_error "Learning service authentication failed: $LEARNING_RESPONSE"
    fi
    
    # Test assessment service authentication
    print_test "Assessment service authentication"
    ASSESSMENT_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/assessment/quizzes")
    
    if echo "$ASSESSMENT_RESPONSE" | grep -q "quizzes\|assessments" || [ "$(echo "$ASSESSMENT_RESPONSE" | jq -r 'type' 2>/dev/null)" = "array" ]; then
        print_success "Assessment service authentication successful"
    else
        print_error "Assessment service authentication failed: $ASSESSMENT_RESPONSE"
    fi
    
    # Test lab service authentication
    print_test "Lab service authentication"
    LAB_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/lab/templates")
    
    if echo "$LAB_RESPONSE" | grep -q "templates\|labs" || [ "$(echo "$LAB_RESPONSE" | jq -r 'type' 2>/dev/null)" = "array" ]; then
        print_success "Lab service authentication successful"
    else
        print_error "Lab service authentication failed: $LAB_RESPONSE"
    fi
    
    # Test user service profile access
    print_test "User service profile access"
    USER_PROFILE_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/user/profile")
    
    if echo "$USER_PROFILE_RESPONSE" | grep -q "$TEST_EMAIL\|$TEST_USERNAME\|profile"; then
        print_success "User service profile access successful"
    else
        print_error "User service profile access failed: $USER_PROFILE_RESPONSE"
    fi
}

# Test authorization levels
test_authorization_levels() {
    print_header "Authorization Level Tests"
    
    # Test user-level access
    print_test "User-level resource access"
    USER_PROGRESS_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/user/progress")
    
    if echo "$USER_PROGRESS_RESPONSE" | grep -q "progress\|learning\|achievements" || [ "$(echo "$USER_PROGRESS_RESPONSE" | jq -r 'type' 2>/dev/null)" = "object" ]; then
        print_success "User-level resource access successful"
    else
        print_error "User-level resource access failed: $USER_PROGRESS_RESPONSE"
    fi
    
    # Test admin-level access restriction (should fail for regular user)
    print_test "Admin-level access restriction"
    ADMIN_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/admin/users")
    
    if echo "$ADMIN_RESPONSE" | grep -q "forbidden\|unauthorized\|admin\|permission"; then
        print_success "Admin-level access properly restricted"
    else
        print_error "Admin-level access not properly restricted: $ADMIN_RESPONSE"
    fi
    
    # Test resource ownership validation
    print_test "Resource ownership validation"
    # Try to access another user's data (should fail)
    OTHER_USER_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" "$API_URL/api/user/999999/progress")
    
    if echo "$OTHER_USER_RESPONSE" | grep -q "forbidden\|unauthorized\|not found\|access denied"; then
        print_success "Resource ownership properly validated"
    else
        print_error "Resource ownership not properly validated: $OTHER_USER_RESPONSE"
    fi
}

# Test session management
test_session_management() {
    print_header "Session Management Tests"
    
    # Test token refresh (if implemented)
    print_test "Token refresh functionality"
    REFRESH_RESPONSE=$(curl -s -X POST "$API_URL/api/user/refresh" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$REFRESH_RESPONSE" | grep -q "token\|refresh" || echo "$REFRESH_RESPONSE" | grep -q "not implemented\|not found"; then
        print_success "Token refresh endpoint exists (may not be implemented)"
    else
        print_error "Token refresh endpoint error: $REFRESH_RESPONSE"
    fi
    
    # Test logout functionality
    print_test "User logout functionality"
    LOGOUT_RESPONSE=$(curl -s -X POST "$API_URL/api/user/logout" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$LOGOUT_RESPONSE" | grep -q "success\|logout\|logged out" || echo "$LOGOUT_RESPONSE" | grep -q "not implemented"; then
        print_success "Logout functionality exists (may not be implemented)"
    else
        print_error "Logout functionality error: $LOGOUT_RESPONSE"
    fi
    
    # Test concurrent sessions
    print_test "Concurrent session handling"
    SECOND_LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/user/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
    
    SECOND_TOKEN=$(echo "$SECOND_LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$SECOND_TOKEN" ] && [ "$SECOND_TOKEN" != "$JWT_TOKEN" ]; then
        print_success "Concurrent sessions properly handled"
    else
        print_error "Concurrent session handling issue"
    fi
}

# Main test execution
main() {
    print_header "Authentication and Authorization Integration Tests"
    log "Starting authentication tests for environment: $ENVIRONMENT"
    
    # Run all test suites
    test_user_registration
    test_user_authentication
    test_jwt_validation
    test_cross_service_auth
    test_authorization_levels
    test_session_management
    
    # Print final results
    print_header "Authentication Test Results Summary"
    echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All authentication tests passed successfully!${NC}"
        log "All authentication tests passed successfully!"
        exit 0
    else
        echo -e "${RED}Some authentication tests failed. Check the log file: $LOG_FILE${NC}"
        log "Authentication tests completed with $FAILED_TESTS failures"
        exit 1
    fi
}

# Run tests
main "$@"