export class ApiError extends Error {
  readonly status: number;
  readonly body: unknown;
  readonly retryAfterSeconds?: number;

  constructor(message: string, status: number, body?: unknown, retryAfterSeconds?: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.body = body;
    this.retryAfterSeconds = retryAfterSeconds;
  }
}

export function isRateLimitError(error: unknown): error is ApiError {
  return error instanceof ApiError && error.status === 429;
}

export function getRateLimitMessage(error: ApiError, fallback: string): string {
  if (error.retryAfterSeconds) {
    return `Quá nhiều yêu cầu. Vui lòng thử lại sau ${error.retryAfterSeconds} giây.`;
  }
  return fallback;
}

export function getErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError) return error.message;
  if (error instanceof Error && error.message) return error.message;

  if (typeof error === "string" && error.trim()) return error;

  if (error && typeof error === "object") {
    const record = error as Record<string, unknown>;
    const message = record.message ?? record.Message;
    if (typeof message === "string" && message.trim()) return message;
  }

  return fallback;
}

export function getErrorMessageFromBody(body: unknown, fallback: string): string {
  if (typeof body === "string" && body.trim()) return body;

  if (body && typeof body === "object") {
    const record = body as Record<string, unknown>;
    const message = record.message ?? record.Message;
    if (typeof message === "string" && message.trim()) return message;
  }

  return fallback;
}
