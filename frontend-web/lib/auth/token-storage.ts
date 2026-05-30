const ACCESS_TOKEN_KEY = "menugreen_access_token";
const REFRESH_TOKEN_KEY = "menugreen_refresh_token";
const FULL_NAME_KEY = "menugreen_full_name";

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

export const tokenStorage = {
  getAccessToken(): string | null {
    if (!isBrowser()) return null;
    return localStorage.getItem(ACCESS_TOKEN_KEY);
  },

  getRefreshToken(): string | null {
    if (!isBrowser()) return null;
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  },

  getFullName(): string | null {
    if (!isBrowser()) return null;
    return localStorage.getItem(FULL_NAME_KEY);
  },

  saveTokens(input: {
    accessToken: string;
    refreshToken: string;
    fullName?: string | null;
  }): void {
    if (!isBrowser()) return;
    localStorage.setItem(ACCESS_TOKEN_KEY, input.accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, input.refreshToken);
    if (input.fullName) {
      localStorage.setItem(FULL_NAME_KEY, input.fullName);
    }
  },

  clear(): void {
    if (!isBrowser()) return;
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(FULL_NAME_KEY);
  },
};
