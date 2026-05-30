"use client";

import { useCallback, useEffect, useState } from "react";
import { subscriptionPlanApi } from "@/features/subscription-plans/api/subscription-plan-api";
import type {
  SubscriptionPlan,
  SubscriptionPlanListParams,
  SubscriptionPlanUpsertRequest,
} from "@/features/subscription-plans/types";
import { getErrorMessage } from "@/lib/api/errors";

export function useSubscriptionPlans() {
  const [filterActive, setFilterActive] = useState<boolean | undefined>(
    undefined,
  );
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const reload = useCallback(async (params?: SubscriptionPlanListParams) => {
    setLoading(true);
    setError(null);

    const isActive = params?.isActive ?? filterActive;

    try {
      const data = await subscriptionPlanApi.getAll({ isActive });
      setPlans(data);
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải danh sách gói thành viên"));
    } finally {
      setLoading(false);
    }
  }, [filterActive]);

  useEffect(() => {
    reload();
  }, [reload]);

  const createPlan = useCallback(
    async (payload: SubscriptionPlanUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await subscriptionPlanApi.create(payload);
        setNotice(`Đã tạo gói "${payload.name}".`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tạo gói thành viên"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [reload],
  );

  const updatePlan = useCallback(
    async (id: string, payload: SubscriptionPlanUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await subscriptionPlanApi.update(id, payload);
        setNotice(`Đã cập nhật gói "${payload.name}".`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật gói thành viên"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [reload],
  );

  const deletePlan = useCallback(
    async (plan: SubscriptionPlan) => {
      setActionLoadingId(plan.id);
      setNotice(null);
      setError(null);

      try {
        await subscriptionPlanApi.delete(plan.id);
        setNotice(`Đã xóa gói "${plan.name}".`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xóa gói thành viên"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [reload],
  );

  const toggleStatus = useCallback(
    async (plan: SubscriptionPlan) => {
      setActionLoadingId(plan.id);
      setNotice(null);
      setError(null);

      try {
        await subscriptionPlanApi.updateStatus(plan.id, {
          isActive: !plan.isActive,
        });
        setNotice(
          `Đã ${plan.isActive ? "vô hiệu hóa" : "kích hoạt"} gói "${plan.name}".`,
        );
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật trạng thái"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [reload],
  );

  return {
    filterActive,
    setFilterActive,
    plans,
    loading,
    saving,
    actionLoadingId,
    error,
    notice,
    reload,
    createPlan,
    updatePlan,
    deletePlan,
    toggleStatus,
  };
}
