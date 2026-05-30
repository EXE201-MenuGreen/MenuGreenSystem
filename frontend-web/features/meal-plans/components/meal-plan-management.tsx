"use client";

import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { PageHeader } from "@/components/layout/page-header";
import { DistributeMealPlanDialog } from "@/features/meal-plans/components/distribute-meal-plan-dialog";
import { MealPlanFormDialog } from "@/features/meal-plans/components/meal-plan-form-dialog";
import { useMealPlans } from "@/features/meal-plans/hooks/use-meal-plans";
import type { MealPlan } from "@/features/meal-plans/types";
import { formatNumber } from "@/lib/utils/format";

export function MealPlanManagement() {
  const {
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
  } = useMealPlans();

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<MealPlan | null>(null);
  const [deleting, setDeleting] = useState<MealPlan | null>(null);
  const [distributing, setDistributing] = useState<MealPlan | null>(null);
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null);

  function handleFilterChange(value: string) {
    const isActive = value === "all" ? undefined : value === "active";
    setFilterActive(isActive);
  }

  async function openEdit(plan: MealPlan) {
    setDetailLoadingId(plan.id);
    try {
      const detail = await loadPlanDetail(plan.id);
      setEditing(detail);
      setFormOpen(true);
    } finally {
      setDetailLoadingId(null);
    }
  }

  async function handleFormSubmit(payload: Parameters<typeof createPlan>[0]) {
    if (editing) {
      await updatePlan(editing.id, payload);
    } else {
      await createPlan(payload);
    }
  }

  async function handleDistribute(targetAudience: string, notes: string) {
    if (!distributing) return;
    await distributePlan(distributing, { targetAudience, notes: notes || null });
    setDistributing(null);
  }

  return (
    <div>
      <PageHeader
        title="Quản lý thực đơn mẫu"
        description="Tạo meal plan mẫu, quản lý trạng thái và phân phối cho user"
        action={
          <Button onClick={() => { setEditing(null); setFormOpen(true); }}>
            Thêm meal plan
          </Button>
        }
      />

      {notice ? (
        <div className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-300">{notice}</div>
      ) : null}
      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">{error}</div>
      ) : null}

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-2xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950">
        <div className="w-48">
          <Select
            label="Trạng thái"
            value={filterActive === undefined ? "all" : filterActive ? "active" : "inactive"}
            onChange={(e) => handleFilterChange(e.target.value)}
          >
            <option value="all">Tất cả</option>
            <option value="active">Đang hoạt động</option>
            <option value="inactive">Đã ẩn</option>
          </Select>
        </div>
        <Button variant="secondary" onClick={() => reload()} loading={loading}>Làm mới</Button>
      </div>

      <div className="overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Meal plan</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Loại</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Thời gian</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Bữa ăn</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Calories</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Trạng thái</th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">Đang tải...</td></tr>
              ) : plans.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">Không có meal plan nào.</td></tr>
              ) : (
                plans.map((plan) => {
                  const isBusy = actionLoadingId === plan.id || detailLoadingId === plan.id;
                  const dateRange =
                    plan.startDate && plan.endDate
                      ? `${plan.startDate} → ${plan.endDate}`
                      : plan.startDate || plan.endDate || "—";

                  return (
                    <tr key={plan.id} className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40">
                      <td className="px-4 py-4">
                        <div className="font-medium text-zinc-900 dark:text-zinc-50">{plan.title}</div>
                        {plan.generatedBy ? (
                          <div className="text-xs text-zinc-500">by {plan.generatedBy}</div>
                        ) : null}
                      </td>
                      <td className="px-4 py-4 text-sm">{plan.planType || "—"}</td>
                      <td className="px-4 py-4 text-sm">{dateRange}</td>
                      <td className="px-4 py-4 text-sm">{formatNumber(plan.items?.length ?? 0)} bữa</td>
                      <td className="px-4 py-4 text-sm">{formatNumber(plan.totalCalories)} kcal</td>
                      <td className="px-4 py-4">
                        <Badge variant={plan.isActive ? "success" : "danger"}>
                          {plan.isActive ? "Hoạt động" : "Ẩn"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex flex-wrap justify-end gap-2">
                          <Button variant="secondary" className="h-9 px-3 text-xs" disabled={isBusy} loading={detailLoadingId === plan.id} onClick={() => openEdit(plan)}>Sửa</Button>
                          <Button variant="ghost" className="h-9 px-3 text-xs" disabled={isBusy} onClick={() => setDistributing(plan)}>Phân phối</Button>
                          <Button variant={plan.isActive ? "ghost" : "primary"} className="h-9 px-3 text-xs" loading={isBusy && !detailLoadingId} onClick={() => toggleStatus(plan)}>
                            {plan.isActive ? "Ẩn" : "Bật"}
                          </Button>
                          <Button variant="danger" className="h-9 px-3 text-xs" disabled={isBusy} onClick={() => setDeleting(plan)}>Xóa</Button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <MealPlanFormDialog
        open={formOpen}
        plan={editing}
        loading={saving}
        onClose={() => { setFormOpen(false); setEditing(null); }}
        onSubmit={handleFormSubmit}
      />

      <DistributeMealPlanDialog
        plan={distributing}
        loading={Boolean(distributing && actionLoadingId === distributing.id)}
        onClose={() => setDistributing(null)}
        onConfirm={handleDistribute}
      />

      {deleting ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
            <h2 className="text-lg font-semibold">Xóa meal plan</h2>
            <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
              Bạn có chắc muốn xóa <span className="font-medium">{deleting.title}</span>?
            </p>
            <div className="mt-6 flex justify-end gap-3">
              <Button variant="secondary" onClick={() => setDeleting(null)} disabled={Boolean(actionLoadingId)}>Hủy</Button>
              <Button variant="danger" loading={actionLoadingId === deleting.id} onClick={async () => { await deletePlan(deleting); setDeleting(null); }}>Xóa</Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
