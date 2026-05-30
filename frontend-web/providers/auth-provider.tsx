"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { useRouter } from "next/navigation";
import { authApi } from "@/features/auth/api/auth-api";
import type { AuthResponse, LoginRequest } from "@/features/auth/types";
import { getErrorMessage } from "@/lib/api/errors";
import { tokenStorage } from "@/lib/auth/token-storage";

interface AuthContextValue {
  isAuthenticated: boolean;
  isReady: boolean;
  fullName: string | null;
  loggingOut: boolean;
  login: (payload: LoginRequest) => Promise<AuthResponse>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [isReady, setIsReady] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [fullName, setFullName] = useState<string | null>(null);
  const [loggingOut, setLoggingOut] = useState(false);

  useEffect(() => {
    const token = tokenStorage.getAccessToken();
    setIsAuthenticated(Boolean(token));
    setFullName(tokenStorage.getFullName());
    setIsReady(true);
  }, []);

  const login = useCallback(async (payload: LoginRequest) => {
    const response = await authApi.login(payload);
    setIsAuthenticated(true);
    setFullName(response.fullName || tokenStorage.getFullName());
    return response;
  }, []);

  const logout = useCallback(async () => {
    setLoggingOut(true);
    try {
      await authApi.logout();
    } finally {
      setIsAuthenticated(false);
      setFullName(null);
      setLoggingOut(false);
      router.replace("/login");
    }
  }, [router]);

  const value = useMemo(
    () => ({
      isAuthenticated,
      isReady,
      fullName,
      loggingOut,
      login,
      logout,
    }),
    [isAuthenticated, isReady, fullName, loggingOut, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuthContext() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuthContext must be used within AuthProvider");
  }
  return context;
}

export function useAuthActions() {
  const { login, logout, loggingOut } = useAuthContext();

  const loginWithErrorHandling = useCallback(
    async (payload: LoginRequest) => {
      try {
        return { success: true as const, data: await login(payload) };
      } catch (error) {
        return {
          success: false as const,
          message: getErrorMessage(error, "Đăng nhập thất bại"),
        };
      }
    },
    [login],
  );

  return { login: loginWithErrorHandling, logout, loggingOut };
}
