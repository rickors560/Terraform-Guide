import { useCallback } from 'react';
import { useAuthStore } from '@/store/authStore';
import api from '@/services/api';
import { API_PATHS } from '@/utils/constants';
import toast from 'react-hot-toast';

interface LoginCredentials {
  email: string;
  password: string;
}

interface AuthResponse {
  token: string;
  refreshToken: string;
  user: {
    id: number;
    email: string;
    name: string;
    role: string;
  };
}

export function useAuth() {
  const { token, isAuthenticated, user, login: storeLogin, logout: storeLogout } = useAuthStore();

  const login = useCallback(
    async (credentials: LoginCredentials) => {
      try {
        const response = await api.post<AuthResponse>(API_PATHS.AUTH.LOGIN, credentials);
        const { token, refreshToken, user } = response.data;
        storeLogin(token, refreshToken, user);
        toast.success(`Welcome back, ${user.name}!`);
        return true;
      } catch {
        return false;
      }
    },
    [storeLogin],
  );

  const logout = useCallback(async () => {
    try {
      if (token) {
        await api.post(API_PATHS.AUTH.LOGOUT);
      }
    } catch {
      // Logout even if the API call fails
    } finally {
      storeLogout();
      toast.success('Logged out successfully');
    }
  }, [token, storeLogout]);

  const refreshSession = useCallback(async () => {
    try {
      const { refreshToken } = useAuthStore.getState();
      if (!refreshToken) {
        storeLogout();
        return false;
      }
      const response = await api.post<AuthResponse>(API_PATHS.AUTH.REFRESH, { refreshToken });
      const { token, refreshToken: newRefreshToken, user } = response.data;
      storeLogin(token, newRefreshToken, user);
      return true;
    } catch {
      storeLogout();
      return false;
    }
  }, [storeLogin, storeLogout]);

  return {
    token,
    isAuthenticated,
    user,
    login,
    logout,
    refreshSession,
  };
}
