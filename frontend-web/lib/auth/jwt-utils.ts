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
