"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import type { MealPlan } from "@/features/meal-plans/types";

const AUDIENCE_OPTIONS = ["Free", "Pro", "Admin", "All"];
const AUDIENCE_LABELS: Record<string, string> = {
  Free: "Miễn phí",
  Pro: "Pro",
  Admin: "Quản trị viên",
  All: "Tất cả",
};

interface DistributeMealPlanDialogProps {
  plan: MealPlan | null;
  loading?: boolean;
  onClose: () => void;
  onConfirm: (targetAudience: string, notes: string) => Promise<void>;
}

export function DistributeMealPlanDialog({
  plan,
  loading = false,
  onClose,
  onConfirm,
}: DistributeMealPlanDialogProps) {
  const [targetAudience, setTargetAudience] = useState("Pro");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    if (plan) {
      setTargetAudience("Pro");
      setNotes("");
    }
  }, [plan]);

  if (!plan) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
        <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          Phân phối meal plan
        </h2>
        <p className="mt-1 text-sm text-zinc-500">{plan.title}</p>

        <div className="mt-4 space-y-4">
          <Select
            label="Đối tượng nhận"
            value={targetAudience}
            onChange={(e) => setTargetAudience(e.target.value)}
          >
            {AUDIENCE_OPTIONS.map((opt) => (
              <option key={opt} value={opt}>{AUDIENCE_LABELS[opt]}</option>
            ))}
          </Select>
          <Input
            label="Ghi chú (tuỳ chọn)"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Tuần 1 — gói Pro"
          />
        </div>

        <div className="mt-6 flex justify-end gap-3">
          <Button variant="secondary" onClick={onClose} disabled={loading}>Hủy</Button>
          <Button
            loading={loading}
            onClick={() => onConfirm(targetAudience, notes)}
          >
            Phân phối
          </Button>
        </div>
      </div>
    </div>
  );
}
