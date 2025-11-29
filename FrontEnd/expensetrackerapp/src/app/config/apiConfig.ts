// API Configuration
// For local development, use: 'http://localhost:8000' (or your local Kong/API gateway URL)
// For Android emulator, use: 'http://10.0.2.2:8000'
// For production, change this value or use a config file
export const API_CONFIG = {
  BASE_URL: 'http://localhost:8000', // Change this for different environments
  ENDPOINTS: {
    AUTH: {
      LOGIN: '/auth/v1/login',
      SIGNUP: '/auth/v1/signup',
      REFRESH_TOKEN: '/auth/v1/refreshToken',
      PING: '/auth/v1/ping',
    },
    EXPENSE: {
      GET_EXPENSES: '/expense/v1/getExpense',
      ADD_EXPENSE: '/expense/v1/addExpense',
    },
    DS: {
      PROCESS_MESSAGE: '/v1/ds/message',
    },
  },
};

