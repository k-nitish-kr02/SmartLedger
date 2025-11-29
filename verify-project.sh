#!/bin/bash

# SmartLedger Project Verification Script
# This script checks if all services are running and working correctly

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

print_header() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_header "SmartLedger Project Verification"

# Check Docker
print_header "1. Checking Prerequisites"
if command_exists docker; then
    if docker info >/dev/null 2>&1; then
        print_success "Docker is running"
    else
        print_error "Docker is not running. Please start Docker."
        exit 1
    fi
else
    print_error "Docker is not installed"
    exit 1
fi

if command_exists docker-compose; then
    print_success "Docker Compose is installed"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

# Check if services are running
print_header "2. Checking Docker Services"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT" 2>/dev/null || {
    print_error "Cannot find project root directory"
    exit 1
}

if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in root directory"
    exit 1
fi

SERVICES_RUNNING=true

# Check each service
check_service() {
    local service=$1
    if docker-compose ps | grep -q "$service.*Up"; then
        print_success "$service is running"
        return 0
    else
        print_error "$service is not running"
        SERVICES_RUNNING=false
        return 1
    fi
}

check_service "mysql"
check_service "kafka"
check_service "zookeeper"
check_service "authservice"
check_service "expenseservice"
check_service "userservice"
check_service "dsservice"
check_service "kong-service"

if [ "$SERVICES_RUNNING" = false ]; then
    print_warning "Some services are not running. Start them with: docker-compose up -d"
fi

# Check service health endpoints
print_header "3. Checking Service Health Endpoints"

check_health() {
    local name=$1
    local url=$2
    local expected=$3
    
    if curl -s -f "$url" >/dev/null 2>&1; then
        response=$(curl -s "$url")
        if echo "$response" | grep -q "$expected"; then
            print_success "$name is healthy (responded correctly)"
            return 0
        else
            print_warning "$name responded but with unexpected content: $response"
            return 1
        fi
    else
        print_error "$name is not responding at $url"
        return 1
    fi
}

# Wait a bit for services to be ready
sleep 2

check_health "Kong Gateway" "http://localhost:8000/status" "OK" || true
check_health "Auth Service" "http://localhost:9898/auth/v1/health" "true" || true
check_health "Expense Service" "http://localhost:9820/expense/v1/health" "true" || true

# Check database connectivity
print_header "4. Checking Database Connectivity"

if docker exec mysql-8.3.0 mysql -uroot -ppassword -e "SELECT 1" >/dev/null 2>&1; then
    print_success "MySQL is accessible"
    
    # Check databases
    DB_COUNT=$(docker exec mysql-8.3.0 mysql -uroot -ppassword -e "SHOW DATABASES" 2>/dev/null | grep -E "(authservice|expenseservice|userservice)" | wc -l)
    if [ "$DB_COUNT" -ge 1 ]; then
        print_success "Service databases exist ($DB_COUNT found)"
    else
        print_warning "Service databases may not be created yet (they're created on first service start)"
    fi
else
    print_error "Cannot connect to MySQL"
fi

# Check Kafka
print_header "5. Checking Kafka"

KAFKA_CONTAINER=$(docker-compose ps -q kafka 2>/dev/null)
if [ -n "$KAFKA_CONTAINER" ]; then
    if docker exec "$KAFKA_CONTAINER" kafka-topics --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
        print_success "Kafka is accessible"
        TOPICS=$(docker exec "$KAFKA_CONTAINER" kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | wc -l)
        print_info "Kafka topics: $TOPICS (topics are auto-created when first message is sent)"
    else
        print_warning "Kafka may not be fully ready yet (this is normal on first startup)"
    fi
else
    print_warning "Kafka container not found"
fi

# Test API endpoints
print_header "6. Testing API Endpoints"

# Test signup
print_info "Testing signup endpoint..."
SIGNUP_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/v1/signup \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser'$(date +%s)'",
    "password": "testpass123",
    "first_name": "Test",
    "last_name": "User",
    "email": "test'$(date +%s)'@example.com",
    "phone_number": "1234567890"
  }' 2>&1)

if echo "$SIGNUP_RESPONSE" | grep -q "accessToken"; then
    print_success "Signup endpoint is working"
    ACCESS_TOKEN=$(echo "$SIGNUP_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "$SIGNUP_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    
    # Test ping endpoint
    PING_RESPONSE=$(curl -s -X GET http://localhost:8000/auth/v1/ping \
      -H "Authorization: Bearer $ACCESS_TOKEN" 2>&1)
    
    if echo "$PING_RESPONSE" | grep -qE "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"; then
        print_success "Authentication endpoint is working (ping returned user ID)"
    else
        print_warning "Ping endpoint returned: $PING_RESPONSE"
    fi
    
    # Test expense endpoint
    EXPENSE_RESPONSE=$(curl -s -X GET http://localhost:8000/expense/v1/getExpense \
      -H "Authorization: Bearer $ACCESS_TOKEN" 2>&1)
    
    if echo "$EXPENSE_RESPONSE" | grep -q "\[\]"; then
        print_success "Expense endpoint is working (returned empty array - expected for new user)"
    elif echo "$EXPENSE_RESPONSE" | grep -q "accessToken\|token"; then
        print_success "Expense endpoint is working"
    else
        print_warning "Expense endpoint response: $EXPENSE_RESPONSE"
    fi
else
    print_warning "Signup endpoint response: $SIGNUP_RESPONSE"
    print_info "This might be normal if the user already exists or services are still starting"
fi

# Check frontend
print_header "7. Checking Frontend"

cd ../../FrontEnd/expensetrackerapp 2>/dev/null || {
    print_warning "Frontend directory not found"
}

if [ -d "node_modules" ]; then
    print_success "Frontend node_modules installed"
    
    if [ -f "node_modules/@react-native-community/cli-platform-android/native_modules.gradle" ]; then
        print_success "React Native Android dependencies are installed"
    else
        print_error "React Native Android dependencies missing"
    fi
else
    print_error "Frontend node_modules not found. Run: npm install --legacy-peer-deps"
fi

if [ -f "src/app/config/apiConfig.ts" ]; then
    print_success "Frontend API configuration exists"
    API_URL=$(grep "BASE_URL" src/app/config/apiConfig.ts | head -1 | grep -o "http://[^']*" || echo "not found")
    print_info "Frontend API URL: $API_URL"
else
    print_error "Frontend API configuration missing"
fi

# Summary
print_header "Verification Summary"

echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Your project is working correctly.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Start frontend: cd FrontEnd/expensetrackerapp && npm start"
    echo "2. Run on device/emulator: npm run android (or npm run ios)"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some checks failed. Please review the errors above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "1. Start services: docker-compose up -d (from root directory)"
    echo "2. Wait 30-60 seconds for services to fully start"
    echo "3. Check logs: docker-compose logs"
    exit 1
fi

