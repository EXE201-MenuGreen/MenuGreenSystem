"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { foodApi } from "@/features/foods/api/food-api";
import type { Food } from "@/features/foods/types";
import type { MealPlan } from "@/features/meal-plans/types";
import {
  emptyMealPlanForm,
  emptyMealPlanItemRow,
  formStateToPayload,
  mealPlanToFormState,
  validateMealPlanForm,
  type MealPlanFormState,
  type MealPlanItemFormRow,
} from "@/features/meal-plans/utils/meal-plan-form";
import { recipeApi } from "@/features/recipes/api/recipe-api";
import type { Recipe } from "@/features/recipes/types";

const MEAL_TYPES = ["Breakfast", "Lunch", "Dinner", "Snack"];

interface MealPlanFormDialogProps {
  plan: MealPlan | null;
  open: boolean;
  loading?: boolean;
  onClose: () => void;
  onSubmit: (payload: ReturnType<typeof formStateToPayload>) => Promise<void>;
}

export function MealPlanFormDialog({
  plan,
  open,
  loading = false,
  onClose,
  onSubmit,
}: MealPlanFormDialogProps) {
  const [form, setForm] = useState<MealPlanFormState>(emptyMealPlanForm());
  const [foods, setFoods] = useState<Food[]>([]);
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setForm(plan ? mealPlanToFormState(plan) : emptyMealPlanForm());
    setError(null);

    Promise.all([
      foodApi.search({}).then((r) => setFoods(r.items)),
      recipeApi.search({}).then((r) => setRecipes(r.items)),
    ]).catch(() => {
      setFoods([]);
      setRecipes([]);
    });
  }, [plan, open]);

  if (!open) return null;

  function updateField<K extends keyof MealPlanFormState>(
    key: K,
    value: MealPlanFormState[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  function updateItemRow(index: number, patch: Partial<MealPlanItemFormRow>) {
    setForm((current) => ({
      ...current,
      items: current.items.map((row, i) =>
        i === index ? { ...row, ...patch } : row,
      ),
    }));
  }

  function addItemRow() {
    setForm((current) => ({
      ...current,
      items: [...current.items, emptyMealPlanItemRow()],
    }));
  }

  function removeItemRow(index: number) {
    setForm((current) => ({
      ...current,
      items: current.items.filter((_, i) => i !== index),
    }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const validationError = validateMealPlanForm(form);
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
      <div className="max-h-[90vh] w-full max-w-4xl overflow-y-auto rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
        <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          {plan ? "Sửa meal plan" : "Thêm meal plan mẫu"}
        </h2>

        <form onSubmit={handleSubmit} className="mt-5 space-y-5">
          <div className="grid gap-4 sm:grid-cols-2">
            <Input label="Tiêu đề *" value={form.title} onChange={(e) => updateField("title", e.target.value)} required />
            <Select label="Loại plan *" value={form.planType} onChange={(e) => updateField("planType", e.target.value)}>
              <option value="weekly">weekly</option>
              <option value="daily">daily</option>
              <option value="custom">custom</option>
            </Select>
            <Input label="Ngày bắt đầu" type="date" value={form.startDate} onChange={(e) => updateField("startDate", e.target.value)} />
            <Input label="Ngày kết thúc" type="date" value={form.endDate} onChange={(e) => updateField("endDate", e.target.value)} />
            <Input label="Calories mục tiêu" type="number" min="0" value={form.targetCalories} onChange={(e) => updateField("targetCalories", e.target.value)} />
            <Input label="Tạo bởi" value={form.generatedBy} onChange={(e) => updateField("generatedBy", e.target.value)} />
          </div>

          <div>
            <div className="mb-3 flex items-center justify-between">
              <h3 className="text-sm font-semibold">Các bữa ăn *</h3>
              <Button type="button" variant="secondary" className="h-8 px-3 text-xs" onClick={addItemRow}>
                + Thêm bữa
              </Button>
            </div>
            <div className="space-y-3">
              {form.items.map((row, index) => (
                <div key={index} className="grid gap-2 rounded-xl border border-zinc-200 p-3 dark:border-zinc-800 sm:grid-cols-6">
                  <Select label="Bữa" value={row.mealType} onChange={(e) => updateItemRow(index, { mealType: e.target.value })}>
                    {MEAL_TYPES.map((t) => (
                      <option key={t} value={t}>{t}</option>
                    ))}
                  </Select>
                  <Select label="Food" value={row.foodId} onChange={(e) => updateItemRow(index, { foodId: e.target.value, ...(e.target.value ? { recipeId: "" } : {}) })}>
                    <option value="">—</option>
                    {foods.map((f) => (
                      <option key={f.id} value={f.id}>{f.nameVi}</option>
                    ))}
                  </Select>
                  <Select label="Recipe" value={row.recipeId} onChange={(e) => updateItemRow(index, { recipeId: e.target.value, ...(e.target.value ? { foodId: "" } : {}) })}>
                    <option value="">—</option>
                    {recipes.map((r) => (
                      <option key={r.id} value={r.id}>{r.title}</option>
                    ))}
                  </Select>
                  <Input label="Ngày" type="date" value={row.plannedDate} onChange={(e) => updateItemRow(index, { plannedDate: e.target.value })} />
                  <Input label="Calories" type="number" min="0" value={row.targetCalories} onChange={(e) => updateItemRow(index, { targetCalories: e.target.value })} />
                  <div className="flex items-end">
                    <Button type="button" variant="ghost" className="h-10 text-xs text-red-600" onClick={() => removeItemRow(index)} disabled={form.items.length <= 1}>
                      Xóa
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={form.isActive} onChange={(e) => updateField("isActive", e.target.checked)} className="h-4 w-4 rounded border-zinc-300 text-emerald-600" />
            Đang hoạt động
          </label>

          {error ? (
            <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">{error}</p>
          ) : null}

          <div className="flex justify-end gap-3 border-t border-zinc-200 pt-4 dark:border-zinc-800">
            <Button type="button" variant="secondary" onClick={onClose} disabled={loading}>Hủy</Button>
            <Button type="submit" loading={loading}>{plan ? "Lưu thay đổi" : "Tạo meal plan"}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
