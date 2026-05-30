"use client";

import { useCallback, useEffect, useState } from "react";
import { mealPlanApi } from "@/features/meal-plans/api/meal-plan-api";
import type {
  MealPlan,
  MealPlanDistributeParams,
  MealPlanListParams,
  MealPlanUpsertRequest,
} from "@/features/meal-plans/types";
import { getErrorMessage } from "@/lib/api/errors";

export function useMealPlans() {
  const [filterActive, setFilterActive] = useState<boolean | undefined>(
    undefined,
  );
  const [plans, setPlans] = useState<MealPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const reload = useCallback(async (params?: MealPlanListParams) => {
    setLoading(true);
    setError(null);

    const isActive = params?.isActive ?? filterActive;

    try {
      const data = await mealPlanApi.getAll({ isActive });
      setPlans(data);
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải danh sách meal plan"));
    } finally {
      setLoading(false);
    }
  }, [filterActive]);

  useEffect(() => {
    reload();
  }, [reload]);

  const createPlan = useCallback(
    async (payload: MealPlanUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await mealPlanApi.create(payload);
        setNotice(`Đã tạo meal plan "${payload.title}".`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tạo meal plan"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [reload],
  );

  const updatePlan = useCallback(
    async (id: string, payload: MealPlanUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await mealPlanApi.update(id, payload);
        setNotice(`Đã cập nhật meal plan "${payload.title}".`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật meal plan"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [reload],
  );

  const deletePlan = useCallback(
    async (plan: MealPlan) => {
      setActionLoadingId(plan.id);
      setNotice(null);
      setError(null);

      try {
        await mealPlanApi.delete(plan.id);
        setNotice(`Đã xóa meal plan "${plan.title}".`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xóa meal plan"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [reload],
  );

  const toggleStatus = useCallback(
    async (plan: MealPlan) => {
      setActionLoadingId(plan.id);
      setNotice(null);
      setError(null);

      try {
        await mealPlanApi.updateStatus(plan.id, { isActive: !plan.isActive });
        setNotice(
          `Đã ${plan.isActive ? "vô hiệu hóa" : "kích hoạt"} "${plan.title}".`,
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

  const distributePlan = useCallback(
    async (plan: MealPlan, params: MealPlanDistributeParams) => {
      setActionLoadingId(plan.id);
      setNotice(null);
      setError(null);

      try {
        const result = await mealPlanApi.distribute(plan.id, params);
        setNotice(result.message || `Đã phân phối cho ${params.targetAudience}.`);
        await reload();
        return result;
      } catch (err) {
        setError(getErrorMessage(err, "Không thể phân phối meal plan"));
        throw err;
      } finally {
        setActionLoadingId(null);
      }
    },
    [reload],
  );

  const loadPlanDetail = useCallback(async (id: string) => {
    return mealPlanApi.getById(id);
  }, []);

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
    distributePlan,
    loadPlanDetail,
  };
}
