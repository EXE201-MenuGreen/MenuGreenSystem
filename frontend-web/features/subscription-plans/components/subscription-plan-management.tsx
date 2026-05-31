"use client";

import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { PageHeader } from "@/components/layout/page-header";
import { SubscriptionPlanFormDialog } from "@/features/subscription-plans/components/subscription-plan-form-dialog";
import { useSubscriptionPlans } from "@/features/subscription-plans/hooks/use-subscription-plans";
import type { SubscriptionPlan } from "@/features/subscription-plans/types";
import { formatNumber, formatVnd } from "@/lib/utils/format";

export function SubscriptionPlanManagement() {
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
    loadPlanDetail,
  } = useSubscriptionPlans();

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<SubscriptionPlan | null>(null);
  const [deleting, setDeleting] = useState<SubscriptionPlan | null>(null);
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null);

  function handleFilterChange(value: string) {
    const isActive = value === "all" ? undefined : value === "active";
    setFilterActive(isActive);
  }

  async function openEdit(plan: SubscriptionPlan) {
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

  return (
    <div>
      <PageHeader
        title="Quản lý gói thành viên"
        description="CRUD gói subscription — Free, Pro, Premium"
        action={
          <Button onClick={() => { setEditing(null); setFormOpen(true); }}>
            Thêm gói
          </Button>
        }
      />

      {notice ? (
        <div className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-300">
          {notice}
        </div>
      ) : null}
      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-2xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950">
        <div className="w-48">
          <Select
            label="Trạng thái"
            value={
              filterActive === undefined
                ? "all"
                : filterActive
                  ? "active"
                  : "inactive"
            }
            onChange={(e) => handleFilterChange(e.target.value)}
          >
            <option value="all">Tất cả</option>
            <option value="active">Đang hoạt động</option>
            <option value="inactive">Đã ẩn</option>
          </Select>
        </div>
        <Button variant="secondary" onClick={() => reload()} loading={loading}>
          Làm mới
        </Button>
      </div>

      <div className="overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Gói</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Thời hạn</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Giá</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Nhóm</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Trạng thái</th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr><td colSpan={6} className="px-4 py-10 text-center text-sm text-zinc-500">Đang tải...</td></tr>
              ) : plans.length === 0 ? (
                <tr><td colSpan={6} className="px-4 py-10 text-center text-sm text-zinc-500">Không có gói nào.</td></tr>
              ) : (
                plans.map((plan) => {
                  const isBusy =
                    actionLoadingId === plan.id || detailLoadingId === plan.id;
                  return (
                    <tr key={plan.id} className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40">
                      <td className="px-4 py-4">
                        <div className="font-medium text-zinc-900 dark:text-zinc-50">{plan.name}</div>
                        {plan.tierLabel ? (
                          <div className="text-sm text-zinc-500">{plan.tierLabel}</div>
                        ) : null}
                        {plan.description ? (
                          <div className="mt-1 text-xs text-zinc-400 line-clamp-2">{plan.description}</div>
                        ) : null}
                      </td>
                      <td className="px-4 py-4 text-sm">
                        {plan.durationDays === 0 ? "Vĩnh viễn" : `${formatNumber(plan.durationDays)} ngày`}
                      </td>
                      <td className="px-4 py-4 text-sm">{formatVnd(plan.priceVnd)}</td>
                      <td className="px-4 py-4">
                        <Badge variant="info">{plan.featureGroup || "—"}</Badge>
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant={plan.isActive ? "success" : "danger"}>
                          {plan.isActive ? "Hoạt động" : "Ẩn"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex justify-end gap-2">
                          <Button variant="secondary" className="h-9 px-3 text-xs" disabled={isBusy} loading={detailLoadingId === plan.id} onClick={() => openEdit(plan)}>Sửa</Button>
                          <Button variant={plan.isActive ? "ghost" : "primary"} className="h-9 px-3 text-xs" loading={isBusy} onClick={() => toggleStatus(plan)}>
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

      <SubscriptionPlanFormDialog
        open={formOpen}
        plan={editing}
        loading={saving}
        onClose={() => { setFormOpen(false); setEditing(null); }}
        onSubmit={handleFormSubmit}
      />

      {deleting ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
            <h2 className="text-lg font-semibold">Xóa gói thành viên</h2>
            <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
              Bạn có chắc muốn xóa <span className="font-medium">{deleting.name}</span>?
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
