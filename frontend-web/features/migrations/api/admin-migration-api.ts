import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";

export interface MigrationStatus {
  gitSha: string;
  dataAccessLayerVersion: string;
  applied: string[];
  pending: string[];
}

export interface MigrationHistory {
  migrations: Array<{
    migrationId: string;
    productVersion: string;
    applied: Date | null;
  }>;
}

export interface MigrationApplyResult {
  appliedBefore: string[];
  appliedAfter: string[];
  newlyApplied: string[];
  message: string;
}

export const migrationApi = {
  getStatus(): Promise<MigrationStatus> {
    return apiClient.get<MigrationStatus>(apiEndpoints.migrations.status);
  },

  getHistory(): Promise<MigrationHistory> {
    return apiClient.get<MigrationHistory>(apiEndpoints.migrations.history);
  },

  apply(): Promise<MigrationApplyResult> {
    return apiClient.post<MigrationApplyResult>(
      apiEndpoints.migrations.apply,
      {},
    );
  },
};
