export function tryGetExpiryEpochSeconds(jwt: string): number | null {
  try {
    const parts = jwt.split(".");
    if (parts.length < 2) return null;

    const normalized = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(
      normalized.length + ((4 - (normalized.length % 4)) % 4),
      "=",
    );
    const payload = JSON.parse(atob(padded)) as { exp?: number | string };

    if (typeof payload.exp === "number") return payload.exp;
    if (typeof payload.exp === "string") {
      const parsed = Number.parseInt(payload.exp, 10);
      return Number.isNaN(parsed) ? null : parsed;
    }

    return null;
  } catch {
    return null;
  }
}

function decodeJwtPayload(jwt: string): Record<string, unknown> | null {
  try {
    const parts = jwt.split(".");
    if (parts.length < 2) return null;

    const normalized = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(
      normalized.length + ((4 - (normalized.length % 4)) % 4),
      "=",
    );
    return JSON.parse(atob(padded)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function tryGetRoleFromToken(jwt: string): string | null {
  const payload = decodeJwtPayload(jwt);
  if (!payload) return null;

  const role =
    payload.role ??
    payload.Role ??
    payload[
      "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
    ];

  return typeof role === "string" && role.length > 0 ? role : null;
}

export function isAdminToken(jwt: string | null | undefined): boolean {
  if (!jwt) return false;
  return tryGetRoleFromToken(jwt) === "Admin";
}
