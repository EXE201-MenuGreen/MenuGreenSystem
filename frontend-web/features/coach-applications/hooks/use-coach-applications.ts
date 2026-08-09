"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { coachApplicationApi } from "@/features/coach-applications/api/coach-application-api";
import type {
  CoachApplication,
  CoachApplicationStatus,
  CoachReviewRequest,
} from "@/features/coach-applications/types";
import { getErrorMessage } from "@/lib/api/errors";

export function useCoachApplications() {
  const [applications, setApplications] = useState<CoachApplication[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [status, setStatus] = useState<CoachApplicationStatus | undefined>(
    "PendingReview",
  );
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await coachApplicationApi.list();
      setApplications(data);
      setSelectedId((current) =>
        current && data.some((item) => item.id === current)
          ? current
          : (data[0]?.id ?? null),
      );
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải danh sách hồ sơ PT"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    coachApplicationApi
      .list()
      .then((data) => {
        if (cancelled) return;
        setApplications(data);
        setSelectedId(data[0]?.id ?? null);
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          setError(getErrorMessage(err, "Không thể tải danh sách hồ sơ PT"));
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = useMemo(() => {
    const keyword = query.trim().toLocaleLowerCase("vi");
    return applications.filter((item) => {
      if (status && item.applicationStatus !== status) return false;
      if (!keyword) return true;
      return [item.fullName, item.email, item.city, item.headline, item.specialty]
        .join(" ")
        .toLocaleLowerCase("vi")
        .includes(keyword);
    });
  }, [applications, query, status]);

  const selected =
    filtered.find((item) => item.id === selectedId) ?? filtered[0] ?? null;

  const review = useCallback(
    async (application: CoachApplication, request: CoachReviewRequest) => {
      setActionLoading(true);
      setError(null);
      setNotice(null);
      try {
        await coachApplicationApi.review(application.id, request);
        setNotice(`Đã cập nhật hồ sơ của ${application.fullName}.`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xử lý hồ sơ PT"));
      } finally {
        setActionLoading(false);
      }
    },
    [reload],
  );

  return {
    applications,
    filtered,
    selected,
    selectedId,
    status,
    query,
    loading,
    actionLoading,
    error,
    notice,
    setSelectedId,
    setStatus,
    setQuery,
    reload,
    review,
  };
}
