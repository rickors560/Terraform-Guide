import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  user: {
    id: number;
    email: string;
    name: string;
    role: string;
  } | null;
  setToken: (token: string, refreshToken?: string) => void;
  setUser: (user: AuthState['user']) => void;
  login: (token: string, refreshToken: string, user: AuthState['user']) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      refreshToken: null,
      isAuthenticated: false,
      user: null,

      setToken: (token, refreshToken) =>
        set({
          token,
          refreshToken: refreshToken ?? null,
          isAuthenticated: true,
        }),

      setUser: (user) => set({ user }),

      login: (token, refreshToken, user) =>
        set({
          token,
          refreshToken,
          isAuthenticated: true,
          user,
        }),

      logout: () =>
        set({
          token: null,
          refreshToken: null,
          isAuthenticated: false,
          user: null,
        }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        token: state.token,
        refreshToken: state.refreshToken,
        isAuthenticated: state.isAuthenticated,
        user: state.user,
      }),
    },
  ),
);
