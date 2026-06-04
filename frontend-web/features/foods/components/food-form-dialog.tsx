"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { foodApi } from "@/features/foods/api/food-api";
import { ALLERGEN_OPTIONS } from "@/features/foods/constants/allergens";
import type { Food } from "@/features/foods/types";
import {
  emptyFoodForm,
  foodToFormState,
  formStateToPayload,
  validateFoodForm,
  type FoodFormState,
} from "@/features/foods/utils/food-form";

interface FoodFormDialogProps {
  food: Food | null;
  open: boolean;
  loading?: boolean;
  onClose: () => void;
  onSubmit: (payload: ReturnType<typeof formStateToPayload>) => Promise<void>;
}

export function FoodFormDialog({
  food,
  open,
  loading = false,
  onClose,
  onSubmit,
}: FoodFormDialogProps) {
  const [form, setForm] = useState<FoodFormState>(emptyFoodForm());
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setForm(food ? foodToFormState(food) : emptyFoodForm());
    setError(null);

    if (food?.id) {
      foodApi
        .getAllergenTags(food.id)
        .then((tags) => {
          setForm((current) => ({
            ...current,
            allergenKeys: tags.allergenKeys ?? [],
          }));
        })
        .catch(() => {
          // Admin có thể chưa có quyền — bỏ qua
        });
    }
  }, [food, open]);

  if (!open) return null;

  function updateField<K extends keyof FoodFormState>(
    key: K,
    value: FoodFormState[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const validationError = validateFoodForm(form);
    if (validationError) {
      setError(validationError);
      return;
    }

    setError(null);
    try {
      await onSubmit(formStateToPayload(form));
      onClose();
    } catch {
      // Error surfaced by parent hook
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div
        className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950"
        role="dialog"
        aria-modal="true"
      >
        <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          {food ? "Sửa món ăn" : "Thêm món ăn mới"}
        </h2>
        <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
          Nhập thông tin dinh dưỡng và mô tả món ăn
        </p>

        <form onSubmit={handleSubmit} className="mt-5 space-y-5">
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
              placeholder="Breakfast, Lunch, ..."
            />
            <Input
              label="URL hình ảnh"
              value={form.imageUrl}
              onChange={(e) => updateField("imageUrl", e.target.value)}
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-700 dark:text-zinc-200">
              Mô tả
            </label>
            <textarea
              value={form.description}
              onChange={(e) => updateField("description", e.target.value)}
              rows={3}
              className="w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm text-zinc-900 outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-100"
            />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
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
              label="Fiber (g)"
              type="number"
              min="0"
              step="0.1"
              value={form.fiberG}
              onChange={(e) => updateField("fiberG", e.target.value)}
            />
            <Input
              label="Giá ước tính (VND)"
              type="number"
              min="0"
              value={form.estimatedPriceVnd}
              onChange={(e) => updateField("estimatedPriceVnd", e.target.value)}
            />
            <Input
              label="Khẩu phần mặc định (g)"
              type="number"
              min="0"
              value={form.defaultServingG}
              onChange={(e) => updateField("defaultServingG", e.target.value)}
            />
          </div>

          <div>
            <p className="text-sm font-medium text-zinc-800 dark:text-zinc-100">
              Dị ứng / thành phần cần cảnh báo
            </p>
            <p className="mt-1 text-xs text-zinc-500">
              Chọn nhãn chuẩn để app mobile đối chiếu với dị ứng người dùng
            </p>
            <div className="mt-3 flex flex-wrap gap-2">
              {ALLERGEN_OPTIONS.map((option) => {
                const selected = form.allergenKeys.includes(option.key);
                return (
                  <button
                    key={option.key}
                    type="button"
                    onClick={() => {
                      const next = selected
                        ? form.allergenKeys.filter((k) => k !== option.key)
                        : [...form.allergenKeys, option.key];
                      updateField("allergenKeys", next);
                    }}
                    className={`rounded-full border px-3 py-1 text-xs font-medium transition ${
                      selected
                        ? "border-emerald-600 bg-emerald-50 text-emerald-800"
                        : "border-zinc-300 text-zinc-600 hover:border-zinc-400"
                    }`}
                  >
                    {option.label}
                  </button>
                );
              })}
            </div>
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
              {food ? "Lưu thay đổi" : "Tạo món ăn"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
