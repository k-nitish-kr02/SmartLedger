# Docker Compose Guide

## Overview

The project now uses a **root-level `docker-compose.yml`** file that orchestrates all services. This makes it much easier to manage the entire stack from one location.

## Quick Start

### Start All Services

```bash
# From root directory
docker-compose up -d
```

### Stop All Services

```bash
docker-compose down
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f authservice
docker-compose logs -f kong-service
```

### Check Status

```bash
docker-compose ps
```

## Services Included

The `docker-compose.yml` includes:

### Infrastructure
- **MySQL** (port 3306) - Database
- **Zookeeper** (port 2181) - Kafka coordination
- **Kafka** (port 9092) - Message queue

### Application Services
- **authservice** (port 9898) - Authentication service
- **userservice** (port 9810) - User management
- **expenseservice** (port 9820) - Expense management
- **dsservice** (port 8010) - Data science/LLM service

### API Gateway
- **kong-service** (port 8000) - API Gateway with custom auth plugin

## Building Services

### Option 1: Build All Services First

```bash
./build-all-services.sh
docker-compose up -d
```

### Option 2: Build and Start in One Command

```bash
docker-compose up -d --build
```

This will build all services that have Dockerfiles and start them.

### Option 3: Use Quick Start Script

```bash
./start-local.sh
```

This builds all services and starts them automatically.

## Service Dependencies

Services start in the correct order thanks to health checks and `depends_on`:

1. **Infrastructure first**: MySQL, Zookeeper, Kafka
2. **Application services**: Auth, User, Expense, DS services
3. **API Gateway last**: Kong (depends on all services)

## Health Checks

All services have health checks configured:
- Infrastructure services check basic connectivity
- Application services check HTTP health endpoints
- Services wait for dependencies to be healthy before starting

## Networking

All services are on the `smartledger-network` bridge network, allowing them to communicate using service names:
- `mysql` (not `localhost`)
- `kafka` (not `localhost`)
- `authservice`, `expenseservice`, etc.

## Volumes

- **mysql-db**: Persistent storage for MySQL data

## Environment Variables

### Service-Specific

Each service has its own environment variables in `docker-compose.yml`:
- Database credentials
- Kafka connection details
- API keys (DS service)

### Override with .env file

Create a `.env` file in the root directory to override defaults:

```env
OPENAI_API_KEY=your-api-key-here
MYSQL_PASSWORD=your-password
```

## Common Commands

### Restart a Service

```bash
docker-compose restart authservice
```

### Rebuild a Service

```bash
docker-compose build authservice
docker-compose up -d authservice
```

### View Service Logs

```bash
docker-compose logs -f --tail=100 authservice
```

### Execute Command in Container

```bash
docker-compose exec authservice sh
docker-compose exec mysql mysql -uroot -ppassword
```

### Stop and Remove Everything

```bash
docker-compose down -v  # -v removes volumes too
```

## Troubleshooting

### Services Won't Start

1. **Check logs:**
   ```bash
   docker-compose logs [service-name]
   ```

2. **Check if ports are in use:**
   ```bash
   lsof -i :8000
   lsof -i :3306
   ```

3. **Rebuild services:**
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Kong Not Starting

Kong depends on other services. Check:
```bash
docker-compose ps
docker-compose logs kong-service
```

Make sure authservice, expenseservice, and dsservice are healthy first.

### Database Connection Issues

1. **Wait for MySQL to be ready:**
   ```bash
   docker-compose logs mysql
   ```
   Look for: `ready for connections`

2. **Test connection:**
   ```bash
   docker-compose exec mysql mysql -uroot -ppassword -e "SELECT 1"
   ```

### Kafka Connection Issues

1. **Check Kafka is ready:**
   ```bash
   docker-compose logs kafka
   ```

2. **Wait for Zookeeper first:**
   Kafka depends on Zookeeper, so make sure Zookeeper is healthy.

## Differences from Old Setup

### Before
- Services defined in `Kong config/expenseTrackerAppDeps/services.yml`
- Kong used volume mounts (not Dockerfile)
- Had to `cd` into nested directory

### Now
- Single `docker-compose.yml` in root
- Kong uses Dockerfile (better for deployment)
- All services build from Dockerfiles
- Health checks ensure proper startup order
- Can run commands from root directory

## Production Considerations

For production:
1. Use environment variables for secrets (not hardcoded)
2. Use Docker secrets or external secret management
3. Configure proper resource limits
4. Use production-grade MySQL (not development setup)
5. Set up proper logging and monitoring
6. Configure backup strategies for volumes

