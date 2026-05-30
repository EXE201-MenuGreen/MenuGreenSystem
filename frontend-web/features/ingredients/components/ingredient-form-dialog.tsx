"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { Ingredient } from "@/features/ingredients/types";
import {
  emptyIngredientForm,
  formStateToPayload,
  ingredientToFormState,
  validateIngredientForm,
  type IngredientFormState,
} from "@/features/ingredients/utils/ingredient-form";

interface IngredientFormDialogProps {
  ingredient: Ingredient | null;
  open: boolean;
  loading?: boolean;
  onClose: () => void;
  onSubmit: (payload: ReturnType<typeof formStateToPayload>) => Promise<void>;
}

export function IngredientFormDialog({
  ingredient,
  open,
  loading = false,
  onClose,
  onSubmit,
}: IngredientFormDialogProps) {
  const [form, setForm] = useState<IngredientFormState>(emptyIngredientForm());
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setForm(ingredient ? ingredientToFormState(ingredient) : emptyIngredientForm());
    setError(null);
  }, [ingredient, open]);

  if (!open) return null;

  function updateField<K extends keyof IngredientFormState>(
    key: K,
    value: IngredientFormState[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const validationError = validateIngredientForm(form);
    if (validationError) {
      setError(validationError);
      return;
    }

    setError(null);
    try {
      await onSubmit(formStateToPayload(form));
      onClose();
    } catch {
      // Parent hook handles error message
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
        <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          {ingredient ? "Sửa nguyên liệu" : "Thêm nguyên liệu mới"}
        </h2>

        <form onSubmit={handleSubmit} className="mt-5 space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <Input
              label="Tên tiếng Việt *"
              value={form.nameVi}
              onChange={(e) => updateField("nameVi", e.target.value)}
              required
            />
            <Input
              label="Tên tiếng Anh"
              value={form.nameEn}
              onChange={(e) => updateField("nameEn", e.target.value)}
            />
            <Input
              label="Danh mục"
              value={form.category}
              onChange={(e) => updateField("category", e.target.value)}
            />
            <Input
              label="Đơn vị mặc định"
              value={form.unitDefault}
              onChange={(e) => updateField("unitDefault", e.target.value)}
              placeholder="g, ml, ..."
            />
            <Input
              label="Calories (kcal)"
              type="number"
              min="0"
              value={form.caloriesKcal}
              onChange={(e) => updateField("caloriesKcal", e.target.value)}
            />
            <Input
              label="Protein (g)"
              type="number"
              min="0"
              step="0.1"
              value={form.proteinG}
              onChange={(e) => updateField("proteinG", e.target.value)}
            />
            <Input
              label="Carbs (g)"
              type="number"
              min="0"
              step="0.1"
              value={form.carbsG}
              onChange={(e) => updateField("carbsG", e.target.value)}
            />
            <Input
              label="Fat (g)"
              type="number"
              min="0"
              step="0.1"
              value={form.fatG}
              onChange={(e) => updateField("fatG", e.target.value)}
            />
            <Input
              label="Giá ước tính (VND)"
              type="number"
              min="0"
              value={form.estimatedPriceVnd}
              onChange={(e) => updateField("estimatedPriceVnd", e.target.value)}
            />
            <Input
              label="URL hình ảnh"
              value={form.imageUrl}
              onChange={(e) => updateField("imageUrl", e.target.value)}
            />
          </div>

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
              {ingredient ? "Lưu thay đổi" : "Tạo nguyên liệu"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
