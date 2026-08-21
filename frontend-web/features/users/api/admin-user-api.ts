import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  AdminGrantMembershipRequest,
  AdminUserMembership,
  UserAdmin,
  UserSearchParams,
  UserSearchResult,
} from "@/features/users/types";

export const adminUserApi = {
  getAll(): Promise<UserAdmin[]> {
    return apiClient.get<UserAdmin[]>(apiEndpoints.adminUser.list);
  },

  search(params?: UserSearchParams): Promise<UserSearchResult> {
    return apiClient.get<UserSearchResult>(
      withQuery(apiEndpoints.adminUser.list, {
        keyword: params?.keyword,
        role: params?.role,
        isActive: params?.isActive,
        membershipStatus: params?.membershipStatus,
        page: params?.page,
        pageSize: params?.pageSize,
      }),
    );
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

  getMemberships(id: string): Promise<AdminUserMembership> {
    return apiClient.get<AdminUserMembership>(apiEndpoints.adminUser.memberships(id));
  },

  grantMembership(id: string, payload: AdminGrantMembershipRequest): Promise<AdminUserMembership> {
    return apiClient.post<AdminUserMembership>(apiEndpoints.adminUser.memberships(id), payload);
  },

  extendMembership(id: string, subscriptionId: string, durationDays: number, note?: string): Promise<AdminUserMembership> {
    return apiClient.post<AdminUserMembership>(
      apiEndpoints.adminUser.extendMembership(id, subscriptionId),
      { durationDays, note },
    );
  },

  revokeMembership(id: string, subscriptionId: string, reason: string): Promise<AdminUserMembership> {
    return apiClient.post<AdminUserMembership>(
      apiEndpoints.adminUser.revokeMembership(id, subscriptionId),
      { reason },
    );
  },
};
