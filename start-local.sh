#!/bin/bash

# Quick start script for local development
# This script builds and starts all services

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "SmartLedger Local Development Setup"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build all services
echo "📦 Building all services..."
"$PROJECT_ROOT/build-all-services.sh"

# Start services using root docker-compose.yml
echo ""
echo "🚀 Starting all services..."
cd "$PROJECT_ROOT"
docker-compose up -d --build

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "✅ Services are starting!"
echo ""
echo "📝 Next steps:"
echo "1. Check logs: docker-compose logs -f"
echo "2. Test API: curl http://localhost:8000/status"
echo "3. Start frontend: cd FrontEnd/expensetrackerapp && npm start"
echo ""
echo "💡 Useful commands:"
echo "   - Stop services: docker-compose down"
echo "   - View logs: docker-compose logs -f [service-name]"
echo "   - Restart service: docker-compose restart [service-name]"
echo ""
echo "🔗 Service URLs:"
echo "   - Kong Gateway: http://localhost:8000"
echo "   - Auth Service: http://localhost:9898"
echo "   - Expense Service: http://localhost:9820"
echo "   - User Service: http://localhost:9810"
echo "   - DS Service: http://localhost:8010"
echo ""

