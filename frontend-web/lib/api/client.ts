import { ApiError, getErrorMessageFromBody } from "@/lib/api/errors";
import { refreshAccessToken } from "@/lib/auth/refresh-access-token";
import { tokenStorage } from "@/lib/auth/token-storage";
import { tryGetExpiryEpochSeconds } from "@/lib/auth/jwt-utils";

type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

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

async function tryRefreshAccessToken(): Promise<boolean> {
  return (await refreshAccessToken()) != null;
}

async function ensureFreshAccessToken(): Promise<void> {
  const accessToken = tokenStorage.getAccessToken();
  if (!accessToken) return;

  const exp = tryGetExpiryEpochSeconds(accessToken);
  if (exp == null) return;

  const nowSec = Math.floor(Date.now() / 1000);
  if (exp - nowSec <= 60) {
    await tryRefreshAccessToken();
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
    const refreshed = await tryRefreshAccessToken();
    if (refreshed) {
      return sendRequest<T>(url, options, false);
    }
  }

  if (!response.ok) {
    // Extract Retry-After header for rate limit errors
    const retryAfterSeconds = response.status === 429
      ? parseInt(response.headers.get("Retry-After") ?? "", 10) || undefined
      : undefined;

    throw new ApiError(
      getErrorMessageFromBody(
        parsedBody,
        response.status === 429
          ? "Quá nhiều yêu cầu. Vui lòng thử lại sau."
          : `Request failed with status ${response.status}`,
      ),
      response.status,
      parsedBody,
      retryAfterSeconds,
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

  patch<T>(url: string, body?: unknown, auth = true): Promise<T> {
    return sendRequest<T>(url, { method: "PATCH", body, auth });
  },

  delete<T>(url: string, auth = true): Promise<T> {
    return sendRequest<T>(url, { method: "DELETE", auth });
  },
};
