"use client";

import { useCallback, useEffect, useState } from "react";
import { aiAdminApi } from "@/features/ai-assistant/api/ai-admin-api";
import type { AiAdminOverview } from "@/features/ai-assistant/types";
import { getErrorMessage } from "@/lib/api/errors";

export function useAiAdmin() {
  const [overview, setOverview] = useState<AiAdminOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await aiAdminApi.getOverview(12);
      setOverview(data);
    } catch (err) {
      setError(getErrorMessage(err, "Khong the tai tong quan AI."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void reload();
    }, 0);

    return () => window.clearTimeout(timer);
  }, [reload]);

  return {
    overview,
    loading,
    error,
    reload,
  };
}
