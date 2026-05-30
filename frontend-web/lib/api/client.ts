import { apiEndpoints } from "@/lib/api/endpoints";
import { ApiError, getErrorMessageFromBody } from "@/lib/api/errors";
import { tokenStorage } from "@/lib/auth/token-storage";
import { tryGetExpiryEpochSeconds } from "@/lib/auth/jwt-utils";

type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";

interface RequestOptions {
  method?: HttpMethod;
  body?: unknown;
  auth?: boolean;
}

async function parseJsonSafe(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) return null;

  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = tokenStorage.getRefreshToken();
  if (!refreshToken) return false;

  try {
    const response = await fetch(apiEndpoints.auth.refreshToken, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });

    if (!response.ok) return false;

    const body = (await parseJsonSafe(response)) as Record<string, unknown>;
    const accessToken =
      (body.accessToken as string | undefined) ??
      (body.AccessToken as string | undefined);
    const nextRefreshToken =
      (body.refreshToken as string | undefined) ??
      (body.RefreshToken as string | undefined);
    const fullName =
      (body.fullName as string | undefined) ??
      (body.FullName as string | undefined);

    if (!accessToken || !nextRefreshToken) return false;

    tokenStorage.saveTokens({
      accessToken,
      refreshToken: nextRefreshToken,
      fullName,
    });
    return true;
  } catch {
    return false;
  }
}

async function ensureFreshAccessToken(): Promise<void> {
  const accessToken = tokenStorage.getAccessToken();
  if (!accessToken) return;

  const exp = tryGetExpiryEpochSeconds(accessToken);
  if (exp == null) return;

  const nowSec = Math.floor(Date.now() / 1000);
  if (exp - nowSec <= 60) {
    await refreshAccessToken();
  }
}

async function buildHeaders(auth: boolean): Promise<HeadersInit> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (auth) {
    const token = tokenStorage.getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  return headers;
}

async function sendRequest<T>(
  url: string,
  options: RequestOptions,
  retryOnUnauthorized = true,
): Promise<T> {
  const { method = "GET", body, auth = true } = options;

  if (auth) {
    await ensureFreshAccessToken();
  }

  const response = await fetch(url, {
    method,
    headers: await buildHeaders(auth),
    body: body == null ? undefined : JSON.stringify(body),
  });

  const parsedBody = await parseJsonSafe(response);

  if (response.status === 401 && auth && retryOnUnauthorized) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      return sendRequest<T>(url, options, false);
    }
  }

  if (!response.ok) {
    throw new ApiError(
      getErrorMessageFromBody(
        parsedBody,
        `Request failed with status ${response.status}`,
      ),
      response.status,
      parsedBody,
    );
  }

  return parsedBody as T;
}

export const apiClient = {
  get<T>(url: string, auth = true): Promise<T> {
    return sendRequest<T>(url, { method: "GET", auth });
  },

  post<T>(url: string, body?: unknown, auth = true): Promise<T> {
    return sendRequest<T>(url, { method: "POST", body, auth });
  },

  put<T>(url: string, body?: unknown, auth = true): Promise<T> {
    return sendRequest<T>(url, { method: "PUT", body, auth });
  },

  delete<T>(url: string, auth = true): Promise<T> {
    return sendRequest<T>(url, { method: "DELETE", auth });
  },
};
