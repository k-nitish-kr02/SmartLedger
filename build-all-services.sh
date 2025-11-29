#!/bin/bash

# Build script for all SmartLedger services
# This script builds all Docker images needed for local development

set -e  # Exit on error

echo "=========================================="
echo "Building SmartLedger Services"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Build Auth Service
print_status "Building Auth Service..."
cd "$PROJECT_ROOT/authService/authservice"
if [ ! -f "./gradlew" ]; then
    print_error "gradlew not found in authService/authservice"
    exit 1
fi
# Fix line endings if needed (CRLF to LF)
sed -i 's/\r$//' ./gradlew 2>/dev/null || true
chmod +x ./gradlew
# Use bash explicitly to handle any line ending issues
bash ./gradlew clean build -x test
if [ $? -eq 0 ]; then
    docker build -t auth-service .
    print_success "Auth Service built successfully"
else
    print_error "Failed to build Auth Service"
    exit 1
fi

# Build Expense Service
print_status "Building Expense Service..."
cd "$PROJECT_ROOT/expenseService/expenseService"
if [ ! -f "./gradlew" ]; then
    print_error "gradlew not found in expenseService/expenseService"
    exit 1
fi
# Fix line endings if needed (CRLF to LF)
sed -i 's/\r$//' ./gradlew 2>/dev/null || true
chmod +x ./gradlew
# Use bash explicitly to handle any line ending issues
bash ./gradlew clean build -x test
if [ $? -eq 0 ]; then
    docker build -t expense-service .
    print_success "Expense Service built successfully"
else
    print_error "Failed to build Expense Service"
    exit 1
fi

# Build User Service
print_status "Building User Service..."
cd "$PROJECT_ROOT/userService/userservice"
if [ ! -f "./gradlew" ]; then
    print_error "gradlew not found in userService/userservice"
    exit 1
fi
# Fix line endings if needed (CRLF to LF)
sed -i 's/\r$//' ./gradlew 2>/dev/null || true
chmod +x ./gradlew
# Use bash explicitly to handle any line ending issues
bash ./gradlew clean build -x test
if [ $? -eq 0 ]; then
    docker build -t user-service .
    print_success "User Service built successfully"
else
    print_error "Failed to build User Service"
    exit 1
fi

# Build DS Service
print_status "Building DS Service..."
cd "$PROJECT_ROOT/DsService/dsService"
if [ ! -f "setup.py" ]; then
    print_error "setup.py not found in DsService/dsService"
    exit 1
fi

# Create dist directory if it doesn't exist
mkdir -p dist

# Build Python package
python3 setup.py sdist
if [ $? -eq 0 ]; then
    docker build -t ds-service .
    print_success "DS Service built successfully"
else
    print_error "Failed to build DS Service"
    exit 1
fi

# Build Kong Service
print_status "Building Kong Gateway..."
cd "$PROJECT_ROOT/Kong config/expenseTrackerAppDeps/kong"
if [ -f "Dockerfile" ]; then
    docker build -t kong-custom:latest .
    print_success "Kong Gateway built successfully"
    print_info "Note: docker-compose will build Kong automatically, this is optional"
else
    print_warning "Kong Dockerfile not found at Kong config/expenseTrackerAppDeps/kong/Dockerfile"
    print_info "docker-compose will use kong:latest image if build fails"
fi

echo ""
print_success "=========================================="
print_success "All services built successfully!"
print_success "=========================================="
echo ""
echo "Next steps:"
echo "1. Start services: docker-compose up -d (from root directory)"
echo "2. Check logs: docker-compose logs -f"
echo "3. Start frontend: cd FrontEnd/expensetrackerapp && npm start"
echo ""
echo "Or use the quick start script: ./start-local.sh"

