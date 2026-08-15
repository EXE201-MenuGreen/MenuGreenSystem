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
import { ApiError, getErrorMessage, isRateLimitError, getRateLimitMessage } from "@/lib/api/errors";
import { isAdminToken, tryGetRoleFromToken } from "@/lib/auth/jwt-utils";
import { tokenStorage } from "@/lib/auth/token-storage";

interface AuthContextValue {
  isAuthenticated: boolean;
  isAdmin: boolean;
  role: string | null;
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
  const [isAdmin, setIsAdmin] = useState(false);
  const [role, setRole] = useState<string | null>(null);
  const [fullName, setFullName] = useState<string | null>(null);
  const [loggingOut, setLoggingOut] = useState(false);

  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      const token = tokenStorage.getAccessToken();
      setIsAuthenticated(Boolean(token));
      setRole(token ? tryGetRoleFromToken(token) : null);
      setIsAdmin(isAdminToken(token));
      setFullName(tokenStorage.getFullName());
      setIsReady(true);
    }, 0);
    return () => window.clearTimeout(timeoutId);
  }, []);

  const login = useCallback(async (payload: LoginRequest) => {
    const response = await authApi.login(payload);

    if (!isAdminToken(response.accessToken)) {
      await authApi.logout();
      throw new ApiError("Tài khoản không có quyền Admin.", 403);
    }

    setIsAuthenticated(true);
    setRole(tryGetRoleFromToken(response.accessToken));
    setIsAdmin(true);
    setFullName(response.fullName || tokenStorage.getFullName());
    return response;
  }, []);

  const logout = useCallback(async () => {
    setLoggingOut(true);
    try {
      await authApi.logout();
    } finally {
      setIsAuthenticated(false);
      setIsAdmin(false);
      setRole(null);
      setFullName(null);
      setLoggingOut(false);
      router.replace("/login");
    }
  }, [router]);

  const value = useMemo(
    () => ({
      isAuthenticated,
      isAdmin,
      role,
      isReady,
      fullName,
      loggingOut,
      login,
      logout,
    }),
    [
      isAuthenticated,
      isAdmin,
      role,
      isReady,
      fullName,
      loggingOut,
      login,
      logout,
    ],
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
        // Handle rate limit (429) with Retry-After info
        if (isRateLimitError(error)) {
          return {
            success: false as const,
            message: getRateLimitMessage(error, "Quá nhiều yêu cầu. Vui lòng thử lại sau."),
          };
        }
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
