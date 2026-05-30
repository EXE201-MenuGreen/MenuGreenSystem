"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { ingredientApi } from "@/features/ingredients/api/ingredient-api";
import type { Ingredient } from "@/features/ingredients/types";
import type { Recipe } from "@/features/recipes/types";
import {
  emptyIngredientRow,
  emptyRecipeForm,
  formStateToPayload,
  recipeToFormState,
  validateRecipeForm,
  type RecipeFormState,
  type RecipeIngredientFormRow,
} from "@/features/recipes/utils/recipe-form";

interface RecipeFormDialogProps {
  recipe: Recipe | null;
  open: boolean;
  loading?: boolean;
  onClose: () => void;
  onSubmit: (payload: ReturnType<typeof formStateToPayload>) => Promise<void>;
}

export function RecipeFormDialog({
  recipe,
  open,
  loading = false,
  onClose,
  onSubmit,
}: RecipeFormDialogProps) {
  const [form, setForm] = useState<RecipeFormState>(emptyRecipeForm());
  const [ingredientOptions, setIngredientOptions] = useState<Ingredient[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setForm(recipe ? recipeToFormState(recipe) : emptyRecipeForm());
    setError(null);

    ingredientApi.search({}).then((result) => setIngredientOptions(result.items)).catch(() => setIngredientOptions([]));
  }, [recipe, open]);

  if (!open) return null;

  function updateField<K extends keyof RecipeFormState>(
    key: K,
    value: RecipeFormState[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  function updateIngredientRow(
    index: number,
    patch: Partial<RecipeIngredientFormRow>,
  ) {
    setForm((current) => ({
      ...current,
      ingredients: current.ingredients.map((row, i) =>
        i === index ? { ...row, ...patch } : row,
      ),
    }));
  }

  function addIngredientRow() {
    setForm((current) => ({
      ...current,
      ingredients: [...current.ingredients, emptyIngredientRow()],
    }));
  }

  function removeIngredientRow(index: number) {
    setForm((current) => ({
      ...current,
      ingredients: current.ingredients.filter((_, i) => i !== index),
    }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const validationError = validateRecipeForm(form);
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
          {recipe ? "Sửa công thức" : "Thêm công thức mới"}
        </h2>

        <form onSubmit={handleSubmit} className="mt-5 space-y-5">
          <div className="grid gap-4 sm:grid-cols-2">
            <Input label="Tiêu đề *" value={form.title} onChange={(e) => updateField("title", e.target.value)} required />
            <Input label="Food ID (tuỳ chọn)" value={form.foodId} onChange={(e) => updateField("foodId", e.target.value)} />
            <Input label="Loại bữa ăn" value={form.mealType} onChange={(e) => updateField("mealType", e.target.value)} placeholder="Breakfast, Lunch..." />
            <Select label="Độ khó" value={form.difficulty} onChange={(e) => updateField("difficulty", e.target.value)}>
              <option value="">—</option>
              <option value="Easy">Easy</option>
              <option value="Medium">Medium</option>
              <option value="Hard">Hard</option>
            </Select>
            <Input label="Thời gian chuẩn bị (phút)" type="number" min="0" value={form.prepTimeMin} onChange={(e) => updateField("prepTimeMin", e.target.value)} />
            <Input label="Thời gian nấu (phút)" type="number" min="0" value={form.cookTimeMin} onChange={(e) => updateField("cookTimeMin", e.target.value)} />
            <Input label="Khẩu phần" type="number" min="0" value={form.servings} onChange={(e) => updateField("servings", e.target.value)} />
            <Input label="Giá ước tính (VND)" type="number" min="0" value={form.estimatedPriceVnd} onChange={(e) => updateField("estimatedPriceVnd", e.target.value)} />
            <Input label="URL hình ảnh" value={form.imageUrl} onChange={(e) => updateField("imageUrl", e.target.value)} />
            <Input label="URL video" value={form.videoUrl} onChange={(e) => updateField("videoUrl", e.target.value)} />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-700 dark:text-zinc-200">Mô tả</label>
            <textarea
              value={form.description}
              onChange={(e) => updateField("description", e.target.value)}
              rows={2}
              className="w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-100"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-700 dark:text-zinc-200">Hướng dẫn nấu</label>
            <textarea
              value={form.instructions}
              onChange={(e) => updateField("instructions", e.target.value)}
              rows={4}
              className="w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-100"
            />
          </div>

          <div>
            <div className="mb-3 flex items-center justify-between">
              <h3 className="text-sm font-semibold text-zinc-900 dark:text-zinc-50">Nguyên liệu</h3>
              <Button type="button" variant="secondary" className="h-8 px-3 text-xs" onClick={addIngredientRow}>
                + Thêm dòng
              </Button>
            </div>
            <div className="space-y-3">
              {form.ingredients.map((row, index) => (
                <div key={index} className="grid gap-2 rounded-xl border border-zinc-200 p-3 dark:border-zinc-800 sm:grid-cols-5">
                  <Select
                    label="Nguyên liệu"
                    value={row.ingredientId}
                    onChange={(e) => updateIngredientRow(index, { ingredientId: e.target.value })}
                  >
                    <option value="">Chọn...</option>
                    {ingredientOptions.map((opt) => (
                      <option key={opt.id} value={opt.id}>{opt.nameVi}</option>
                    ))}
                  </Select>
                  <Input label="Số lượng" type="number" min="0" step="0.1" value={row.quantity} onChange={(e) => updateIngredientRow(index, { quantity: e.target.value })} />
                  <Input label="Đơn vị" value={row.unit} onChange={(e) => updateIngredientRow(index, { unit: e.target.value })} />
                  <Input label="Ghi chú" value={row.notes} onChange={(e) => updateIngredientRow(index, { notes: e.target.value })} />
                  <div className="flex items-end">
                    <Button type="button" variant="ghost" className="h-10 text-xs text-red-600" onClick={() => removeIngredientRow(index)} disabled={form.ingredients.length <= 1}>
                      Xóa
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <label className="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-200">
            <input type="checkbox" checked={form.isActive} onChange={(e) => updateField("isActive", e.target.checked)} className="h-4 w-4 rounded border-zinc-300 text-emerald-600 focus:ring-emerald-500" />
            Đang hoạt động
          </label>

          {error ? (
            <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">{error}</p>
          ) : null}

          <div className="flex justify-end gap-3 border-t border-zinc-200 pt-4 dark:border-zinc-800">
            <Button type="button" variant="secondary" onClick={onClose} disabled={loading}>Hủy</Button>
            <Button type="submit" loading={loading}>{recipe ? "Lưu thay đổi" : "Tạo công thức"}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
