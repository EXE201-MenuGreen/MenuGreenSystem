"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import type { SubscriptionPlan } from "@/features/subscription-plans/types";
import {
  emptySubscriptionPlanForm,
  formStateToPayload,
  planToFormState,
  validateSubscriptionPlanForm,
  type SubscriptionPlanFormState,
} from "@/features/subscription-plans/utils/subscription-plan-form";

interface SubscriptionPlanFormDialogProps {
  plan: SubscriptionPlan | null;
  open: boolean;
  loading?: boolean;
  onClose: () => void;
  onSubmit: (payload: ReturnType<typeof formStateToPayload>) => Promise<void>;
}

export function SubscriptionPlanFormDialog({
  plan,
  open,
  loading = false,
  onClose,
  onSubmit,
}: SubscriptionPlanFormDialogProps) {
  const [form, setForm] = useState<SubscriptionPlanFormState>(
    emptySubscriptionPlanForm(),
  );
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setForm(plan ? planToFormState(plan) : emptySubscriptionPlanForm());
    setError(null);
  }, [plan, open]);

  if (!open) return null;

  function updateField<K extends keyof SubscriptionPlanFormState>(
    key: K,
    value: SubscriptionPlanFormState[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const validationError = validateSubscriptionPlanForm(form);
    if (validationError) {
      setError(validationError);
      return;
    }

    setError(null);
    try {
      await onSubmit(formStateToPayload(form));
      onClose();
    } catch {
      // Parent handles error
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-lg rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
        <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          {plan ? "Sửa gói thành viên" : "Thêm gói thành viên"}
        </h2>

        <form onSubmit={handleSubmit} className="mt-5 space-y-4">
          <Input
            label="Tên gói *"
            value={form.name}
            onChange={(e) => updateField("name", e.target.value)}
            required
          />
          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-700 dark:text-zinc-200">
              Mô tả
            </label>
            <textarea
              value={form.description}
              onChange={(e) => updateField("description", e.target.value)}
              rows={2}
              className="w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-100"
            />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <Input
              label="Thời hạn (ngày)"
              type="number"
              min="0"
              value={form.durationDays}
              onChange={(e) => updateField("durationDays", e.target.value)}
              placeholder="0 = vĩnh viễn"
            />
            <Input
              label="Giá (VND)"
              type="number"
              min="0"
              value={form.priceVnd}
              onChange={(e) => updateField("priceVnd", e.target.value)}
            />
          </div>
          <Select
            label="Nhóm tính năng"
            value={form.featureGroup}
            onChange={(e) => updateField("featureGroup", e.target.value)}
          >
            <option value="basic">basic</option>
            <option value="pro">pro</option>
            <option value="premium">premium</option>
          </Select>
          <label className="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-200">
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => updateField("isActive", e.target.checked)}
              className="h-4 w-4 rounded border-zinc-300 text-emerald-600 focus:ring-emerald-500"
            />
            Đang hoạt động
          </label>

          {error ? (
            <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">
              {error}
            </p>
          ) : null}

          <div className="flex justify-end gap-3 border-t border-zinc-200 pt-4 dark:border-zinc-800">
            <Button type="button" variant="secondary" onClick={onClose} disabled={loading}>
              Hủy
            </Button>
            <Button type="submit" loading={loading}>
              {plan ? "Lưu thay đổi" : "Tạo gói"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
