# Local Development Setup Guide

This guide will help you set up and run the SmartLedger project locally.

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Java 21** (for building Java services)
- **Gradle** (or use the gradlew wrapper included)
- **Python 3.11+** (for DS service)
- **Node.js 18+** and npm/yarn (for React Native frontend)
- **React Native CLI** (for mobile app development)

## Quick Start

### Step 1: Build All Services

Run the build script to create all Docker images:

```bash
chmod +x build-all-services.sh
./build-all-services.sh
```

This will:
- Build Auth Service (Java/Spring Boot)
- Build Expense Service (Java/Spring Boot)
- Build User Service (Java/Spring Boot)
- Build DS Service (Python/Flask)
- Create Docker images for all services

### Step 2: Start Infrastructure Services

Navigate to the Kong config directory and start all services:

```bash
cd "Kong config/expenseTrackerAppDeps"
docker-compose -f services.yml up -d
```

This will start:
- MySQL database
- Kafka + Zookeeper
- Auth Service
- Expense Service
- User Service
- DS Service
- Kong API Gateway

### Step 3: Verify Services are Running

Check if all containers are up:

```bash
docker-compose -f services.yml ps
```

Check logs for any errors:

```bash
docker-compose -f services.yml logs -f
```

### Step 4: Configure Frontend

The frontend is already configured to use `http://localhost:8000` (Kong gateway) by default.

If you need to change the API URL, edit:
```
FrontEnd/expensetrackerapp/src/app/config/apiConfig.ts
```

Or set environment variable:
```bash
export API_BASE_URL=http://localhost:8000
```

### Step 5: Start Frontend

For React Native development:

```bash
cd FrontEnd/expensetrackerapp

# Install dependencies (if not already done)
npm install
# or
yarn install

# Start Metro bundler
npm start
# or
yarn start

# In another terminal, run on your platform
npm run android  # For Android
npm run ios      # For iOS
```

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Kong Gateway | 8000 | http://localhost:8000 |
| Kong Admin | 7990 | http://localhost:7990 |
| Auth Service | 9898 | http://localhost:9898 |
| Expense Service | 9820 | http://localhost:9820 |
| User Service | 9810 | http://localhost:9810 |
| DS Service | 8010 | http://localhost:8010 |
| MySQL | 3306 | localhost:3306 |
| Kafka | 9092 | localhost:9092 |
| Zookeeper | 2181 | localhost:2181 |

## Environment Variables

### Services (via docker-compose)

All services use these environment variables (set in `services.yml`):

- `KAFKA_HOST`: kafka (or localhost if running outside Docker)
- `KAFKA_PORT`: 9092
- `MYSQL_HOST`: mysql (or localhost if running outside Docker)
- `MYSQL_PORT`: 3306
- `MYSQL_USER`: test
- `MYSQL_PASSWORD`: password
- `MYSQL_DB`: varies by service (authservice, expenseservice, userservice)

### DS Service

- `OPENAI_API_KEY`: Your OpenAI/Mistral API key (can be set in services.yml or via environment)

### Frontend

- `API_BASE_URL`: Base URL for API calls (defaults to http://localhost:8000)

## Database Setup

MySQL databases are automatically created when services start (via `createDatabaseIfNotExist=true` in Spring Boot config).

Databases created:
- `authservice`
- `expenseservice`
- `userservice`

## Testing the Setup

### 1. Test Kong Gateway

```bash
curl http://localhost:8000/status
```

Should return: `{"message":"OK"}`

### 2. Test Auth Service (direct)

```bash
curl http://localhost:9898/auth/v1/health
```

Should return: `true`

### 3. Test Auth Service (via Kong)

```bash
# Sign up
curl -X POST http://localhost:8000/auth/v1/signup \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123",
    "first_name": "Test",
    "last_name": "User",
    "email": "test@example.com",
    "phone_number": "1234567890"
  }'

# Login
curl -X POST http://localhost:8000/auth/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

### 4. Test Expense Service (via Kong, requires auth)

```bash
# Get expenses (requires Bearer token from login)
curl -X GET http://localhost:8000/expense/v1/getExpense \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Troubleshooting

### Services won't start

1. **Check if ports are already in use:**
   ```bash
   lsof -i :8000
   lsof -i :9898
   lsof -i :9820
   ```

2. **Check Docker logs:**
   ```bash
   docker-compose -f services.yml logs [service-name]
   ```

3. **Rebuild services if code changed:**
   ```bash
   ./build-all-services.sh
   docker-compose -f services.yml up -d --build
   ```

### Database connection issues

1. **Wait for MySQL to be ready:**
   ```bash
   docker-compose -f services.yml logs mysql
   ```
   Wait for: `ready for connections`

2. **Check MySQL is accessible:**
   ```bash
   docker exec -it mysql-8.3.0 mysql -u root -ppassword -e "SHOW DATABASES;"
   ```

### Kafka connection issues

1. **Check Kafka is running:**
   ```bash
   docker-compose -f services.yml ps kafka
   ```

2. **Check Kafka logs:**
   ```bash
   docker-compose -f services.yml logs kafka
   ```

### Frontend can't connect to API

1. **Verify Kong is running:**
   ```bash
   curl http://localhost:8000/status
   ```

2. **Check API_BASE_URL in frontend config:**
   ```typescript
   // FrontEnd/expensetrackerapp/src/app/config/apiConfig.ts
   BASE_URL: 'http://localhost:8000'
   ```

3. **For Android emulator, use:**
   ```typescript
   BASE_URL: 'http://10.0.2.2:8000'  // Android emulator special IP
   ```

4. **For iOS simulator, use:**
   ```typescript
   BASE_URL: 'http://localhost:8000'  // Works directly
   ```

### Kong custom-auth plugin not working

1. **Check Kong logs:**
   ```bash
   docker-compose -f services.yml logs kong-service
   ```

2. **Verify custom-auth plugin is loaded:**
   ```bash
   curl http://localhost:7990/plugins/enabled
   ```

3. **Check Kong config:**
   ```bash
   docker exec -it $(docker-compose -f services.yml ps -q kong-service) kong config dump
   ```

## Stopping Services

To stop all services:

```bash
cd "Kong config/expenseTrackerAppDeps"
docker-compose -f services.yml down
```

To stop and remove volumes (clears databases):

```bash
docker-compose -f services.yml down -v
```

## Development Workflow

1. **Make code changes** in your IDE
2. **Rebuild affected service:**
   ```bash
   # For Java services
   cd authService/authservice
   ./gradlew build
   docker build -t auth-service .
   
   # For Python service
   cd DsService/dsService
   python3 setup.py sdist
   docker build -t ds-service .
   ```
3. **Restart service:**
   ```bash
   docker-compose -f services.yml restart [service-name]
   ```

## Additional Notes

- **First startup may take 2-3 minutes** as services wait for MySQL and Kafka to be ready
- **Kafka topics are auto-created** when first message is sent
- **Database schemas are auto-created** by Hibernate/JPA on first startup
- **All services use snake_case** for JSON field names
- **Kong routes all requests** through `/auth/v1`, `/expense/v1`, `/v1/ds` paths

## Need Help?

Check the logs:
```bash
# All services
docker-compose -f services.yml logs -f

# Specific service
docker-compose -f services.yml logs -f authservice
```

