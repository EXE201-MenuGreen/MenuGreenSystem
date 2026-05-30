export class ApiError extends Error {
  readonly status: number;
  readonly body: unknown;

  constructor(message: string, status: number, body?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.body = body;
  }
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
