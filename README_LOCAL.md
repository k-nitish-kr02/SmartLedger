# SmartLedger - Local Development

## Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Build and start all services
./start-local.sh
```

### Option 2: Manual Setup

```bash
# 1. Build all services
./build-all-services.sh

# 2. Start services (from root directory)
docker-compose up -d

# 3. Start frontend
cd FrontEnd/expensetrackerapp
npm install
npm start
```

### Option 3: Build and Start in One Command

```bash
# From root directory - builds and starts everything
docker-compose up -d --build
```

## What's Fixed for Local Development

✅ **Root-level docker-compose.yml** - Single file to manage all services  
✅ **Kong Dockerfile** - Now uses Dockerfile instead of volume mounts  
✅ **Kong Configuration** - Updated to use local service URLs  
✅ **Environment Variables** - Added missing MySQL credentials  
✅ **Build Scripts** - Automated Docker image building  
✅ **Frontend API Config** - Configured for localhost:8000  
✅ **Service Discovery** - All services use Docker service names  
✅ **Health Checks** - Services wait for dependencies before starting  

## Architecture

```
Frontend (React Native)
    ↓
Kong API Gateway (port 8000)
    ↓
┌─────────────┬──────────────┬──────────────┐
│ Auth Service│ Expense Service│ User Service │
│  (9898)     │   (9820)      │   (9810)     │
└─────────────┴──────────────┴──────────────┘
    ↓              ↓              ↓
    └──────────────┴──────────────┘
              ↓
        Kafka (9092)
              ↓
        MySQL (3306)
```

## Documentation

- **Full Setup Guide**: See [LOCAL_SETUP_GUIDE.md](./LOCAL_SETUP_GUIDE.md)
- **Breakage Fixes**: See [BREAKAGE_FIXES.md](./BREAKAGE_FIXES.md)

## Troubleshooting

If services don't start:

1. Check Docker is running: `docker info`
2. Check logs: `cd "Kong config/expenseTrackerAppDeps" && docker-compose -f services.yml logs`
3. Rebuild services: `./build-all-services.sh`
4. Restart services: `docker-compose -f services.yml restart`

For detailed troubleshooting, see [LOCAL_SETUP_GUIDE.md](./LOCAL_SETUP_GUIDE.md#troubleshooting).

