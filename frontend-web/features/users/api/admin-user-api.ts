import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import type { UserAdmin } from "@/features/users/types";

export const adminUserApi = {
  getAll(): Promise<UserAdmin[]> {
    return apiClient.get<UserAdmin[]>(apiEndpoints.adminUser.list);
  },

  getById(id: string): Promise<UserAdmin> {
    return apiClient.get<UserAdmin>(apiEndpoints.adminUser.byId(id));
  },

  lock(id: string): Promise<UserAdmin> {
    return apiClient.patch<UserAdmin>(apiEndpoints.adminUser.lock(id));
  },

  unlock(id: string): Promise<UserAdmin> {
    return apiClient.patch<UserAdmin>(apiEndpoints.adminUser.unlock(id));
  },
};
