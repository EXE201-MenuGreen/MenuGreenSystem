import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import { ApiError } from "@/lib/api/errors";
import { tokenStorage } from "@/lib/auth/token-storage";
import type { AuthResponse, LoginRequest } from "@/features/auth/types";

export const authApi = {
  async login(payload: LoginRequest): Promise<AuthResponse> {
    const body = await apiClient.post<Record<string, unknown>>(
      apiEndpoints.auth.login,
      payload,
      false,
    );

    const accessToken =
      (body.accessToken as string | undefined) ??
      (body.AccessToken as string | undefined);
    const refreshToken =
      (body.refreshToken as string | undefined) ??
      (body.RefreshToken as string | undefined);

    if (!accessToken || !refreshToken) {
      throw new ApiError("Invalid login response", 500, body);
    }

    const authResponse: AuthResponse = {
      userId: String(body.userId ?? body.UserId ?? ""),
      email: String(body.email ?? body.Email ?? payload.email),
      fullName: String(body.fullName ?? body.FullName ?? ""),
      accessToken,
      refreshToken,
    };

    tokenStorage.saveTokens({
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      fullName: authResponse.fullName,
    });

    return authResponse;
  },

  async logout(): Promise<void> {
    const refreshToken = tokenStorage.getRefreshToken();

    try {
      if (refreshToken) {
        await apiClient.post(
          apiEndpoints.auth.logout,
          { refreshToken },
          false,
        );
      }
    } finally {
      tokenStorage.clear();
    }
  },
};
