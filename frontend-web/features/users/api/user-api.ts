import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";
import type { AssignRoleRequest } from "@/features/users/types";
import type { MessageResponse } from "@/types/common";

export const userApi = {
  assignRole(id: string, payload: AssignRoleRequest): Promise<MessageResponse> {
    return apiClient.put<MessageResponse>(
      apiEndpoints.user.assignRole(id),
      payload,
    );
  },
};
