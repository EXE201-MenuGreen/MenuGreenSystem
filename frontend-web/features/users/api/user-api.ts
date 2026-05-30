import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import type { AssignRoleRequest, UserAdmin } from "@/features/users/types";
import type { MessageResponse } from "@/types/common";

export const userApi = {
  getAll(): Promise<UserAdmin[]> {
    return apiClient.get<UserAdmin[]>(apiEndpoints.user.list);
  },

  getById(id: string): Promise<UserAdmin> {
    return apiClient.get<UserAdmin>(apiEndpoints.user.byId(id));
  },

  toggleStatus(id: string): Promise<MessageResponse> {
    return apiClient.put<MessageResponse>(apiEndpoints.user.toggleStatus(id));
  },

  assignRole(id: string, payload: AssignRoleRequest): Promise<MessageResponse> {
    return apiClient.put<MessageResponse>(
      apiEndpoints.user.assignRole(id),
      payload,
    );
  },
};
