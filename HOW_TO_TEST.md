# How to Test Your SmartLedger Project

This guide shows you multiple ways to verify your project is working correctly.

## Quick Test (Automated)

Run the verification script:

```bash
./verify-project.sh
```

This script will:
- ✅ Check if Docker is running
- ✅ Verify all services are up
- ✅ Test health endpoints
- ✅ Check database connectivity
- ✅ Test API endpoints
- ✅ Verify frontend setup

## Manual Testing Steps

### Step 1: Verify Services are Running

```bash
cd "Kong config/expenseTrackerAppDeps"
docker-compose -f services.yml ps
```

**Expected:** All services should show "Up" status:
- mysql-8.3.0
- zookeeper
- kafka
- authservice
- expenseservice
- userservice
- dsservice
- kong-service

### Step 2: Test Kong Gateway

```bash
curl http://localhost:8000/status
```

**Expected Response:**
```json
{"message":"OK"}
```

### Step 3: Test Auth Service (Direct)

```bash
curl http://localhost:9898/auth/v1/health
```

**Expected Response:**
```json
true
```

### Step 4: Test Signup Endpoint (via Kong)

```bash
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
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token": "uuid-refresh-token",
  "userId": "user-uuid"
}
```

### Step 5: Test Login Endpoint

```bash
curl -X POST http://localhost:8000/auth/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token": "uuid-refresh-token"
}
```

### Step 6: Test Authenticated Endpoint

First, get an access token from login, then:

```bash
# Replace YOUR_ACCESS_TOKEN with the token from login response
curl -X GET http://localhost:8000/expense/v1/getExpense \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
[]
```
(Empty array for new user, or array of expenses)

### Step 7: Test DS Service

```bash
# First get user ID from ping
USER_ID=$(curl -s -X GET http://localhost:8000/auth/v1/ping \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN")

# Then test DS service
curl -X POST http://localhost:8000/v1/ds/message \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "X-User-Id: $USER_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "You spent Rs. 500 at Amazon on 2024-11-28"
  }'
```

**Expected Response:**
```json
{
  "amount": "500",
  "merchant": "Amazon",
  "currency": "inr",
  "user_id": "user-uuid",
  "external_id": "uuid"
}
```

### Step 8: Verify Frontend

```bash
cd FrontEnd/expensetrackerapp

# Check if node_modules exists
ls node_modules

# Check API config
cat src/app/config/apiConfig.ts | grep BASE_URL

# Start Metro bundler
npm start
```

**Expected:**
- `node_modules` directory exists
- API URL is `http://localhost:8000` (or your configured URL)
- Metro bundler starts without errors

## Testing Frontend App

### On Android Emulator

1. Start Android emulator
2. In one terminal:
   ```bash
   cd FrontEnd/expensetrackerapp
   npm start
   ```
3. In another terminal:
   ```bash
   cd FrontEnd/expensetrackerapp
   npm run android
   ```

### On iOS Simulator (Mac only)

1. Start iOS Simulator
2. In one terminal:
   ```bash
   cd FrontEnd/expensetrackerapp
   npm start
   ```
3. In another terminal:
   ```bash
   cd FrontEnd/expensetrackerapp
   npm run ios
   ```

### On Physical Device

1. Connect device via USB
2. Enable USB debugging (Android) or trust computer (iOS)
3. Follow same steps as emulator/simulator

## End-to-End Test Flow

### Complete User Journey Test

1. **Start all services:**
   ```bash
   cd "Kong config/expenseTrackerAppDeps"
   docker-compose -f services.yml up -d
   ```

2. **Wait for services to be ready** (30-60 seconds)

3. **Test signup:**
   ```bash
   curl -X POST http://localhost:8000/auth/v1/signup \
     -H "Content-Type: application/json" \
     -d '{
       "username": "newuser",
       "password": "password123",
       "first_name": "New",
       "last_name": "User",
       "email": "newuser@test.com",
       "phone_number": "9876543210"
     }'
   ```
   Save the `accessToken` from response.

4. **Test login:**
   ```bash
   curl -X POST http://localhost:8000/auth/v1/login \
     -H "Content-Type: application/json" \
     -d '{
       "username": "newuser",
       "password": "password123"
     }'
   ```

5. **Test getting expenses:**
   ```bash
   curl -X GET http://localhost:8000/expense/v1/getExpense \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

6. **Test adding expense via DS service:**
   ```bash
   curl -X POST http://localhost:8000/v1/ds/message \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -H "X-User-Id: YOUR_USER_ID" \
     -H "Content-Type: application/json" \
     -d '{
       "message": "You spent $50 at Walmart"
     }'
   ```

7. **Verify expense was created:**
   ```bash
   curl -X GET http://localhost:8000/expense/v1/getExpense \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```
   Should now show the expense created in step 6.

## Common Issues and Solutions

### Services Not Starting

**Problem:** `docker-compose ps` shows services as "Exit" or "Restarting"

**Solution:**
```bash
# Check logs
docker-compose -f services.yml logs [service-name]

# Restart services
docker-compose -f services.yml restart

# Rebuild if needed
docker-compose -f services.yml up -d --build
```

### API Returns 401 Unauthorized

**Problem:** Getting 401 errors on authenticated endpoints

**Solution:**
- Make sure you're including the `Authorization: Bearer TOKEN` header
- Token might be expired, try logging in again
- Check Kong logs: `docker-compose -f services.yml logs kong-service`

### Frontend Can't Connect

**Problem:** Frontend shows network errors

**Solution:**
- Verify Kong is running: `curl http://localhost:8000/status`
- Check API URL in `src/app/config/apiConfig.ts`
- For Android emulator, use `http://10.0.2.2:8000` instead of `localhost:8000`
- Check if services are accessible: `docker-compose -f services.yml ps`

### Database Connection Errors

**Problem:** Services can't connect to MySQL

**Solution:**
```bash
# Check MySQL is running
docker-compose -f services.yml ps mysql

# Check MySQL logs
docker-compose -f services.yml logs mysql

# Test MySQL connection
docker exec -it mysql-8.3.0 mysql -uroot -ppassword -e "SELECT 1"
```

## Health Check Endpoints

All services have health endpoints:

- **Kong:** `http://localhost:8000/status`
- **Auth Service:** `http://localhost:9898/auth/v1/health`
- **Expense Service:** `http://localhost:9820/expense/v1/health`
- **DS Service:** `http://localhost:8010/health`

## Monitoring Services

### View All Logs

```bash
cd "Kong config/expenseTrackerAppDeps"
docker-compose -f services.yml logs -f
```

### View Specific Service Logs

```bash
docker-compose -f services.yml logs -f authservice
docker-compose -f services.yml logs -f expenseservice
docker-compose -f services.yml logs -f kong-service
```

### Check Service Status

```bash
docker-compose -f services.yml ps
```

## Success Criteria

Your project is working correctly if:

✅ All Docker services show "Up" status  
✅ Health endpoints return expected responses  
✅ Signup creates a new user successfully  
✅ Login returns access token  
✅ Authenticated endpoints work with token  
✅ DS service processes messages and creates expenses  
✅ Frontend can connect to API  
✅ Frontend app builds and runs on device/emulator  

## Quick Verification Checklist

- [ ] Docker is running
- [ ] All services are up (`docker-compose ps`)
- [ ] Kong responds at `http://localhost:8000/status`
- [ ] Can signup new user
- [ ] Can login and get token
- [ ] Can fetch expenses with token
- [ ] DS service processes messages
- [ ] Frontend node_modules installed
- [ ] Frontend API config points to correct URL
- [ ] Frontend app runs on device/emulator

Run `./verify-project.sh` to automatically check all of these!

