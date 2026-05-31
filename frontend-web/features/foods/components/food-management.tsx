"use client";

import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { PageHeader } from "@/components/layout/page-header";
import { FoodFormDialog } from "@/features/foods/components/food-form-dialog";
import { useFoods, defaultFoodFilters } from "@/features/foods/hooks/use-foods";
import type { Food } from "@/features/foods/types";
import { formatNumber, formatVnd } from "@/lib/utils/format";

export function FoodManagement() {
  const {
    filters,
    setFilters,
    foods,
    totalCount,
    loading,
    saving,
    actionLoadingId,
    error,
    notice,
    search,
    createFood,
    updateFood,
    deleteFood,
    loadFoodDetail,
  } = useFoods();

  const [formOpen, setFormOpen] = useState(false);
  const [editingFood, setEditingFood] = useState<Food | null>(null);
  const [deletingFood, setDeletingFood] = useState<Food | null>(null);
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null);

  function openCreate() {
    setEditingFood(null);
    setFormOpen(true);
  }

  async function openEdit(food: Food) {
    setDetailLoadingId(food.id);
    try {
      const detail = await loadFoodDetail(food.id);
      setEditingFood(detail);
      setFormOpen(true);
    } finally {
      setDetailLoadingId(null);
    }
  }

  function closeForm() {
    setFormOpen(false);
    setEditingFood(null);
  }

  async function handleSearchSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await search(filters);
  }

  async function handleFormSubmit(
    payload: Parameters<typeof createFood>[0],
  ) {
    if (editingFood) {
      await updateFood(editingFood.id, payload);
    } else {
      await createFood(payload);
    }
  }

  async function confirmDelete() {
    if (!deletingFood) return;
    await deleteFood(deletingFood);
    setDeletingFood(null);
  }

  return (
    <div>
      <PageHeader
        title="Quản lý món ăn"
        description="Tìm kiếm, thêm, sửa và xóa món ăn trong hệ thống"
        action={
          <Button onClick={openCreate}>Thêm món ăn</Button>
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

      <form
        onSubmit={handleSearchSubmit}
        className="mb-4 grid gap-3 rounded-2xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950 sm:grid-cols-2 lg:grid-cols-5"
      >
        <Input
          label="Từ khóa"
          placeholder="Tên món..."
          value={filters.keyword ?? ""}
          onChange={(e) =>
            setFilters((current) => ({ ...current, keyword: e.target.value }))
          }
        />
        <Input
          label="Danh mục"
          placeholder="Lunch, Salad..."
          value={filters.category ?? ""}
          onChange={(e) =>
            setFilters((current) => ({ ...current, category: e.target.value }))
          }
        />
        <Select
          label="Protein"
          value={filters.proteinLevel ?? ""}
          onChange={(e) =>
            setFilters((current) => ({
              ...current,
              proteinLevel: e.target.value,
            }))
          }
        >
          <option value="">Tất cả</option>
          <option value="high">Cao (≥ 20g)</option>
          <option value="low">Thấp (&lt; 20g)</option>
        </Select>
        <Input
          label="Calories tối đa"
          type="number"
          min="0"
          value={filters.maxCalories ?? ""}
          onChange={(e) =>
            setFilters((current) => ({
              ...current,
              maxCalories: e.target.value
                ? Number(e.target.value)
                : undefined,
            }))
          }
        />
        <Input
          label="Giá tối đa (VND)"
          type="number"
          min="0"
          value={filters.maxPriceVnd ?? ""}
          onChange={(e) =>
            setFilters((current) => ({
              ...current,
              maxPriceVnd: e.target.value
                ? Number(e.target.value)
                : undefined,
            }))
          }
        />
        <div className="flex items-end gap-2 sm:col-span-2 lg:col-span-5">
          <Button type="submit" loading={loading}>
            Tìm kiếm
          </Button>
          <Button
            type="button"
            variant="secondary"
            onClick={() => {
              setFilters(defaultFoodFilters);
              search(defaultFoodFilters);
            }}
          >
            Xóa bộ lọc
          </Button>
        </div>
      </form>

      <p className="mb-3 text-sm text-zinc-500">
        Tìm thấy {totalCount} món ăn
      </p>

      <div className="overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Món ăn
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Danh mục
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Calories
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Protein
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Giá
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Trạng thái
                </th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Thao tác
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">
                    Đang tải...
                  </td>
                </tr>
              ) : foods.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">
                    Không có món ăn nào.
                  </td>
                </tr>
              ) : (
                foods.map((food) => {
                  const isBusy =
                    actionLoadingId === food.id || detailLoadingId === food.id;

                  return (
                    <tr
                      key={food.id}
                      className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40"
                    >
                      <td className="px-4 py-4">
                        <div className="font-medium text-zinc-900 dark:text-zinc-50">
                          {food.nameVi}
                        </div>
                        {food.nameEn ? (
                          <div className="text-sm text-zinc-500">{food.nameEn}</div>
                        ) : null}
                      </td>
                      <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                        {food.category || "—"}
                      </td>
                      <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                        {formatNumber(food.caloriesKcal)}
                      </td>
                      <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                        {formatNumber(food.proteinG)} g
                      </td>
                      <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                        {formatVnd(food.estimatedPriceVnd)}
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant={food.isActive ? "success" : "danger"}>
                          {food.isActive ? "Hoạt động" : "Ẩn"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="secondary"
                            className="h-9 px-3 text-xs"
                            disabled={isBusy}
                            loading={detailLoadingId === food.id}
                            onClick={() => openEdit(food)}
                          >
                            Sửa
                          </Button>
                          <Button
                            variant="danger"
                            className="h-9 px-3 text-xs"
                            loading={isBusy}
                            onClick={() => setDeletingFood(food)}
                          >
                            Xóa
                          </Button>
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

      <FoodFormDialog
        open={formOpen}
        food={editingFood}
        loading={saving}
        onClose={closeForm}
        onSubmit={handleFormSubmit}
      />

      {deletingFood ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
            <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
              Xóa món ăn
            </h2>
            <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
              Bạn có chắc muốn xóa{" "}
              <span className="font-medium">{deletingFood.nameVi}</span>? Hành
              động này không thể hoàn tác.
            </p>
            <div className="mt-6 flex justify-end gap-3">
              <Button
                variant="secondary"
                onClick={() => setDeletingFood(null)}
                disabled={Boolean(actionLoadingId)}
              >
                Hủy
              </Button>
              <Button
                variant="danger"
                loading={actionLoadingId === deletingFood.id}
                onClick={confirmDelete}
              >
                Xóa
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
