import { apiClient } from "@/lib/api/client";
import { apiEndpoints } from "@/lib/api/endpoints";

export interface JobTriggerResult {
  message: string;
  jobName: string;
  triggeredAt: string;
}

export const jobApi = {
  trigger(jobName: string): Promise<JobTriggerResult> {
    return apiClient.post<JobTriggerResult>(
      apiEndpoints.jobs.trigger(jobName),
      {},
    );
  },
};
