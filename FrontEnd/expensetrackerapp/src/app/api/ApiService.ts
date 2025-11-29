import AsyncStorage from '@react-native-async-storage/async-storage';
import {API_CONFIG} from '../config/apiConfig';

interface ApiResponse<T> {
  data?: T;
  error?: string;
  status: number;
}

class ApiService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = API_CONFIG.BASE_URL;
  }

  /**
   * Get access token from storage
   */
  private async getAccessToken(): Promise<string | null> {
    return await AsyncStorage.getItem('accessToken');
  }

  /**
   * Get refresh token from storage
   */
  private async getRefreshToken(): Promise<string | null> {
    return await AsyncStorage.getItem('refreshToken');
  }

  /**
   * Store tokens in AsyncStorage
   */
  private async storeTokens(accessToken: string, refreshToken: string): Promise<void> {
    await AsyncStorage.setItem('accessToken', accessToken);
    await AsyncStorage.setItem('refreshToken', refreshToken);
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshAccessToken(): Promise<boolean> {
    try {
      const refreshToken = await this.getRefreshToken();
      if (!refreshToken) {
        return false;
      }

      const response = await fetch(`${this.baseUrl}${API_CONFIG.ENDPOINTS.AUTH.REFRESH_TOKEN}`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: JSON.stringify({
          token: refreshToken,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        await this.storeTokens(data.accessToken, data.token);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error refreshing token:', error);
      return false;
    }
  }

  /**
   * Make authenticated API request with automatic token refresh
   */
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {},
    retryOn401: boolean = true,
  ): Promise<ApiResponse<T>> {
    try {
      const accessToken = await this.getAccessToken();
      
      const headers: HeadersInit = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        ...options.headers,
      };

      if (accessToken) {
        headers.Authorization = `Bearer ${accessToken}`;
      }

      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        ...options,
        headers,
      });

      // Handle 401 Unauthorized - try to refresh token
      if (response.status === 401 && retryOn401) {
        const refreshed = await this.refreshAccessToken();
        if (refreshed) {
          // Retry the request once with new token
          return this.makeRequest<T>(endpoint, options, false);
        } else {
          // Refresh failed, user needs to login again
          await AsyncStorage.removeItem('accessToken');
          await AsyncStorage.removeItem('refreshToken');
          return {
            status: 401,
            error: 'Session expired. Please login again.',
          };
        }
      }

      const contentType = response.headers.get('content-type');
      let data: T | null = null;

      if (contentType && contentType.includes('application/json')) {
        const text = await response.text();
        data = text ? JSON.parse(text) : null;
      } else {
        const text = await response.text();
        data = text as unknown as T;
      }

      if (!response.ok) {
        return {
          status: response.status,
          error: data && typeof data === 'object' && 'message' in data 
            ? (data as any).message 
            : `Request failed with status ${response.status}`,
        };
      }

      return {
        status: response.status,
        data: data as T,
      };
    } catch (error) {
      console.error('API request error:', error);
      return {
        status: 0,
        error: error instanceof Error ? error.message : 'Network error occurred',
      };
    }
  }

  /**
   * Login user
   */
  async login(username: string, password: string): Promise<ApiResponse<{accessToken: string; token: string; userId?: string}>> {
    const response = await this.makeRequest<{accessToken: string; token: string; userId?: string}>(
      API_CONFIG.ENDPOINTS.AUTH.LOGIN,
      {
        method: 'POST',
        body: JSON.stringify({username, password}),
      },
      false, // Don't retry on 401 for login
    );

    if (response.data) {
      await this.storeTokens(response.data.accessToken, response.data.token);
    }

    return response;
  }

  /**
   * Sign up user
   */
  async signup(userData: {
    first_name: string;
    last_name: string;
    email: string;
    phone_number: string;
    password: string;
    username: string;
  }): Promise<ApiResponse<{accessToken: string; token: string; userId?: string}>> {
    const response = await this.makeRequest<{accessToken: string; token: string; userId?: string}>(
      API_CONFIG.ENDPOINTS.AUTH.SIGNUP,
      {
        method: 'POST',
        body: JSON.stringify(userData),
      },
      false, // Don't retry on 401 for signup
    );

    if (response.data) {
      await this.storeTokens(response.data.accessToken, response.data.token);
    }

    return response;
  }

  /**
   * Check if user is logged in
   */
  async isLoggedIn(): Promise<boolean> {
    const response = await this.makeRequest<string>(
      API_CONFIG.ENDPOINTS.AUTH.PING,
      {
        method: 'GET',
      },
    );

    if (response.status === 200 && response.data) {
      // Check if response is a valid UUID (user ID)
      const isValidUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        response.data.trim(),
      );
      return isValidUUID;
    }
    return false;
  }

  /**
   * Get expenses for current user
   */
  async getExpenses(): Promise<ApiResponse<any[]>> {
    return this.makeRequest<any[]>(API_CONFIG.ENDPOINTS.EXPENSE.GET_EXPENSES, {
      method: 'GET',
    });
  }

  /**
   * Add expense
   */
  async addExpense(expense: {
    amount: string;
    merchant: string;
    currency?: string;
  }): Promise<ApiResponse<boolean>> {
    return this.makeRequest<boolean>(API_CONFIG.ENDPOINTS.EXPENSE.ADD_EXPENSE, {
      method: 'POST',
      body: JSON.stringify(expense),
    });
  }

  /**
   * Process message through DS service
   */
  async processMessage(message: string): Promise<ApiResponse<any>> {
    // Get user ID from ping endpoint first
    const pingResponse = await this.makeRequest<string>(
      API_CONFIG.ENDPOINTS.AUTH.PING,
      {method: 'GET'},
    );

    if (!pingResponse.data) {
      return {
        status: 401,
        error: 'User not authenticated',
      };
    }

    const userId = pingResponse.data.trim();

    return this.makeRequest<any>(API_CONFIG.ENDPOINTS.DS.PROCESS_MESSAGE, {
      method: 'POST',
      headers: {
        'X-User-Id': userId,
      },
      body: JSON.stringify({message}),
    });
  }
}

export default new ApiService();

