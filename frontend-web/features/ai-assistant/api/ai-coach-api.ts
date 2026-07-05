import type {
  AiChatRequest,
  AiChatResponse,
  AiCoachLoginPayload,
  AiCoachSession,
  AiConversationDetail,
  AiConversationSummary,
} from "@/features/ai-assistant/types";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import { ApiError, getErrorMessageFromBody } from "@/lib/api/errors";

const SESSION_KEY = "menugreen_ai_coach_session";

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

function getSession(): AiCoachSession | null {
  if (!isBrowser()) return null;

  const raw = window.sessionStorage.getItem(SESSION_KEY);
  if (!raw) return null;

  try {
    return JSON.parse(raw) as AiCoachSession;
  } catch {
    window.sessionStorage.removeItem(SESSION_KEY);
    return null;
  }
}

function saveSession(session: AiCoachSession): void {
  if (!isBrowser()) return;
  window.sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

function clearSession(): void {
  if (!isBrowser()) return;
  window.sessionStorage.removeItem(SESSION_KEY);
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

async function refreshSession(current: AiCoachSession): Promise<AiCoachSession | null> {
  const response = await fetch(apiEndpoints.auth.refreshToken, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ refreshToken: current.refreshToken }),
  });

  const body = await parseJsonSafe(response);
  if (!response.ok || !body || typeof body !== "object") {
    clearSession();
    return null;
  }

  const record = body as Record<string, unknown>;
  const accessToken = String(record.accessToken ?? record.AccessToken ?? "");
  const refreshToken = String(record.refreshToken ?? record.RefreshToken ?? "");

  if (!accessToken || !refreshToken) {
    clearSession();
    return null;
  }

  const nextSession: AiCoachSession = {
    accessToken,
    refreshToken,
    email: String(record.email ?? record.Email ?? current.email),
    fullName: String(record.fullName ?? record.FullName ?? current.fullName),
    userId: String(record.userId ?? record.UserId ?? current.userId),
  };

  saveSession(nextSession);
  return nextSession;
}

async function sendAuthorizedRequest<T>(
  url: string,
  options: {
    method?: "GET" | "POST";
    body?: unknown;
  } = {},
  retryOnUnauthorized = true,
): Promise<T> {
  const session = getSession();
  if (!session) {
    throw new ApiError("Ban chua dang nhap cho AI Coach.", 401);
  }

  const response = await fetch(url, {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${session.accessToken}`,
    },
    body: options.body == null ? undefined : JSON.stringify(options.body),
  });

  const parsedBody = await parseJsonSafe(response);

  if (response.status === 401 && retryOnUnauthorized) {
    const refreshed = await refreshSession(session);
    if (refreshed) {
      return sendAuthorizedRequest<T>(url, options, false);
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

export const aiCoachApi = {
  getSession,
  clearSession,

  async login(payload: AiCoachLoginPayload): Promise<AiCoachSession> {
    const response = await fetch(apiEndpoints.auth.login, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const body = await parseJsonSafe(response);
    if (!response.ok || !body || typeof body !== "object") {
      throw new ApiError(
        getErrorMessageFromBody(body, "Dang nhap AI Coach that bai."),
        response.status,
        body,
      );
    }

    const record = body as Record<string, unknown>;
    const accessToken = String(record.accessToken ?? record.AccessToken ?? "");
    const refreshToken = String(record.refreshToken ?? record.RefreshToken ?? "");

    if (!accessToken || !refreshToken) {
      throw new ApiError("Phan hoi dang nhap khong hop le.", 500, body);
    }

    const session: AiCoachSession = {
      accessToken,
      refreshToken,
      email: String(record.email ?? record.Email ?? payload.email),
      fullName: String(record.fullName ?? record.FullName ?? ""),
      userId: String(record.userId ?? record.UserId ?? ""),
    };

    saveSession(session);
    return session;
  },

  getConversations(take = 20): Promise<AiConversationSummary[]> {
    return sendAuthorizedRequest<AiConversationSummary[]>(
      withQuery(apiEndpoints.nutritionAssistant.conversations, { take }),
    );
  },

  getConversation(conversationId: string): Promise<AiConversationDetail> {
    return sendAuthorizedRequest<AiConversationDetail>(
      apiEndpoints.nutritionAssistant.conversationById(conversationId),
    );
  },

  sendMessage(payload: AiChatRequest): Promise<AiChatResponse> {
    return sendAuthorizedRequest<AiChatResponse>(
      apiEndpoints.nutritionAssistant.chat,
      {
        method: "POST",
        body: payload,
      },
    );
  },
};
