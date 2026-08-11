import { apiClient } from "@/lib/api/client";
import { apiEndpoints, withQuery } from "@/lib/api/endpoints";
import type {
  CoachApplication,
  CoachApplicationStatus,
  CoachReviewRequest,
} from "@/features/coach-applications/types";

export const coachApplicationApi = {
  list(status?: CoachApplicationStatus): Promise<CoachApplication[]> {
    return apiClient.get<CoachApplication[]>(
      withQuery(apiEndpoints.coachApplication.list, { status }),
    );
  },

  getById(id: string): Promise<CoachApplication> {
    return apiClient.get<CoachApplication>(
      apiEndpoints.coachApplication.byId(id),
    );
  },

  review(id: string, request: CoachReviewRequest): Promise<CoachApplication> {
    return apiClient.post<CoachApplication>(
      apiEndpoints.coachApplication.review(id),
      request,
    );
  },
};
