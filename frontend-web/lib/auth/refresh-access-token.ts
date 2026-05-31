import { apiEndpoints } from "@/lib/api/endpoints";
import { ApiError } from "@/lib/api/errors";
import { tokenStorage } from "@/lib/auth/token-storage";
import type { AuthResponse } from "@/features/auth/types";

async function parseJsonSafe(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) return null;

  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function mapAuthResponse(
  body: Record<string, unknown>,
  fallbackEmail = "",
): AuthResponse | null {
  const accessToken =
    (body.accessToken as string | undefined) ??
    (body.AccessToken as string | undefined);
  const refreshToken =
    (body.refreshToken as string | undefined) ??
    (body.RefreshToken as string | undefined);

  if (!accessToken || !refreshToken) return null;

  return {
    userId: String(body.userId ?? body.UserId ?? ""),
    email: String(body.email ?? body.Email ?? fallbackEmail),
    fullName: String(body.fullName ?? body.FullName ?? ""),
    accessToken,
    refreshToken,
  };
}

export async function refreshAccessToken(): Promise<AuthResponse | null> {
  const refreshToken = tokenStorage.getRefreshToken();
  if (!refreshToken) return null;

  try {
    const response = await fetch(apiEndpoints.auth.refreshToken, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });

    if (!response.ok) return null;

    const body = (await parseJsonSafe(response)) as Record<string, unknown>;
    const authResponse = mapAuthResponse(body);
    if (!authResponse) return null;

    tokenStorage.saveTokens({
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      fullName: authResponse.fullName,
    });

    return authResponse;
  } catch {
    return null;
  }
}

export async function refreshAccessTokenOrThrow(): Promise<AuthResponse> {
  const authResponse = await refreshAccessToken();
  if (!authResponse) {
    throw new ApiError("No refresh token", 401);
  }

  return authResponse;
}
