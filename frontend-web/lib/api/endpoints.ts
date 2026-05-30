const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5000/api";

export const apiEndpoints = {
  baseUrl: API_BASE_URL,
  auth: {
    login: `${API_BASE_URL}/Auth/login`,
    refreshToken: `${API_BASE_URL}/Auth/refresh-token`,
    logout: `${API_BASE_URL}/Auth/logout`,
  },
  user: {
    list: `${API_BASE_URL}/User`,
    byId: (id: string) => `${API_BASE_URL}/User/${id}`,
    toggleStatus: (id: string) => `${API_BASE_URL}/User/${id}/toggle-status`,
    assignRole: (id: string) => `${API_BASE_URL}/User/${id}/assign-role`,
  },
  food: {
    base: `${API_BASE_URL}/Food`,
    byId: (id: string) => `${API_BASE_URL}/Food/${id}`,
  },
  ingredient: {
    base: `${API_BASE_URL}/Ingredient`,
    byId: (id: string) => `${API_BASE_URL}/Ingredient/${id}`,
  },
  recipe: {
    base: `${API_BASE_URL}/Recipe`,
    byId: (id: string) => `${API_BASE_URL}/Recipe/${id}`,
  },
} as const;
