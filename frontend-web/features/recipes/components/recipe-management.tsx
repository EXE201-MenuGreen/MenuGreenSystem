"use client";

import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { PageHeader } from "@/components/layout/page-header";
import { RecipeFormDialog } from "@/features/recipes/components/recipe-form-dialog";
import {
  defaultRecipeFilters,
  useRecipes,
} from "@/features/recipes/hooks/use-recipes";
import type { Recipe } from "@/features/recipes/types";
import { formatNumber, formatVnd } from "@/lib/utils/format";

const DIFFICULTY_LABELS: Record<string, string> = {
  Easy: "Dễ",
  Medium: "Trung bình",
  Hard: "Khó",
};

export function RecipeManagement() {
  const {
    filters,
    setFilters,
    recipes,
    totalCount,
    loading,
    saving,
    actionLoadingId,
    error,
    notice,
    search,
    createRecipe,
    updateRecipe,
    deleteRecipe,
    loadRecipeDetail,
  } = useRecipes();

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Recipe | null>(null);
  const [deleting, setDeleting] = useState<Recipe | null>(null);
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null);

  async function openCreate() {
    setEditing(null);
    setFormOpen(true);
  }

  async function openEdit(recipe: Recipe) {
    setDetailLoadingId(recipe.id);
    try {
      const detail = await loadRecipeDetail(recipe.id);
      setEditing(detail);
      setFormOpen(true);
    } finally {
      setDetailLoadingId(null);
    }
  }

  async function handleFormSubmit(payload: Parameters<typeof createRecipe>[0]) {
    if (editing) {
      await updateRecipe(editing.id, payload);
    } else {
      await createRecipe(payload);
    }
  }

  return (
    <div>
      <PageHeader
        title="Quản lý công thức"
        description="Tìm kiếm, thêm, sửa và xóa công thức nấu ăn"
        action={<Button onClick={openCreate}>Thêm công thức</Button>}
      />

      {notice ? (
        <div className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-300">{notice}</div>
      ) : null}
      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">{error}</div>
      ) : null}

      <form
        onSubmit={(e) => { e.preventDefault(); search(filters); }}
        className="mb-4 grid gap-3 rounded-2xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950 sm:grid-cols-2 lg:grid-cols-4"
      >
        <Input label="Từ khóa" value={filters.keyword ?? ""} onChange={(e) => setFilters((c) => ({ ...c, keyword: e.target.value }))} />
        <Input label="Loại bữa ăn" value={filters.mealType ?? ""} onChange={(e) => setFilters((c) => ({ ...c, mealType: e.target.value }))} />
        <Select label="Độ khó" value={filters.difficulty ?? ""} onChange={(e) => setFilters((c) => ({ ...c, difficulty: e.target.value }))}>
          <option value="">Tất cả</option>
          <option value="Easy">Dễ</option>
          <option value="Medium">Trung bình</option>
          <option value="Hard">Khó</option>
        </Select>
        <div className="flex items-end gap-2 sm:col-span-2 lg:col-span-4">
          <Button type="submit" loading={loading}>Tìm kiếm</Button>
          <Button type="button" variant="secondary" onClick={() => { setFilters(defaultRecipeFilters); search(defaultRecipeFilters); }}>Xóa bộ lọc</Button>
        </div>
      </form>

      <p className="mb-3 text-sm text-zinc-500">Tìm thấy {totalCount} công thức</p>

      <div className="overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Công thức</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Bữa ăn</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Thời gian</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Khẩu phần</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Giá</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Trạng thái</th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">Đang tải...</td></tr>
              ) : recipes.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">Không có công thức nào.</td></tr>
              ) : (
                recipes.map((recipe) => {
                  const isBusy = actionLoadingId === recipe.id || detailLoadingId === recipe.id;
                  const totalTime = recipe.totalTimeMin ?? ((recipe.prepTimeMin ?? 0) + (recipe.cookTimeMin ?? 0));
                  return (
                    <tr key={recipe.id} className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40">
                      <td className="px-4 py-4">
                        <div className="font-medium text-zinc-900 dark:text-zinc-50">{recipe.title}</div>
                        {recipe.difficulty ? <div className="text-sm text-zinc-500">{DIFFICULTY_LABELS[recipe.difficulty] ?? recipe.difficulty}</div> : null}
                      </td>
                      <td className="px-4 py-4 text-sm">{recipe.mealType || "—"}</td>
                      <td className="px-4 py-4 text-sm">{totalTime ? `${totalTime} phút` : "—"}</td>
                      <td className="px-4 py-4 text-sm">{formatNumber(recipe.servings)}</td>
                      <td className="px-4 py-4 text-sm">{formatVnd(recipe.estimatedPriceVnd)}</td>
                      <td className="px-4 py-4">
                        <Badge variant={recipe.isActive ? "success" : "danger"}>
                          {recipe.isActive ? "Hoạt động" : "Ẩn"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex justify-end gap-2">
                          <Button variant="secondary" className="h-9 px-3 text-xs" disabled={isBusy} loading={detailLoadingId === recipe.id} onClick={() => openEdit(recipe)}>Sửa</Button>
                          <Button variant="danger" className="h-9 px-3 text-xs" loading={actionLoadingId === recipe.id} onClick={() => setDeleting(recipe)}>Xóa</Button>
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

      <RecipeFormDialog
        open={formOpen}
        recipe={editing}
        loading={saving}
        onClose={() => { setFormOpen(false); setEditing(null); }}
        onSubmit={handleFormSubmit}
      />

      {deleting ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
            <h2 className="text-lg font-semibold">Xóa công thức</h2>
            <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
              Bạn có chắc muốn xóa <span className="font-medium">{deleting.title}</span>?
            </p>
            <div className="mt-6 flex justify-end gap-3">
              <Button variant="secondary" onClick={() => setDeleting(null)} disabled={Boolean(actionLoadingId)}>Hủy</Button>
              <Button variant="danger" loading={actionLoadingId === deleting.id} onClick={async () => { await deleteRecipe(deleting); setDeleting(null); }}>Xóa</Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
