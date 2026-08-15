"use client";

import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/layout/page-header";
import { IngredientFormDialog } from "@/features/ingredients/components/ingredient-form-dialog";
import {
  defaultIngredientFilters,
  useIngredients,
} from "@/features/ingredients/hooks/use-ingredients";
import type { Ingredient } from "@/features/ingredients/types";
import { formatNumber, formatVnd } from "@/lib/utils/format";
import { translateData } from "@/lib/utils/data-translator";

export function IngredientManagement() {
  const {
    filters,
    setFilters,
    ingredients,
    totalCount,
    loading,
    saving,
    actionLoadingId,
    error,
    notice,
    search,
    createIngredient,
    updateIngredient,
    deleteIngredient,
    loadIngredientDetail,
  } = useIngredients();

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Ingredient | null>(null);
  const [deleting, setDeleting] = useState<Ingredient | null>(null);
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null);

  async function openEdit(ingredient: Ingredient) {
    setDetailLoadingId(ingredient.id);
    try {
      const detail = await loadIngredientDetail(ingredient.id);
      setEditing(detail);
      setFormOpen(true);
    } finally {
      setDetailLoadingId(null);
    }
  }

  async function handleFormSubmit(
    payload: Parameters<typeof createIngredient>[0],
  ) {
    if (editing) {
      await updateIngredient(editing.id, payload);
    } else {
      await createIngredient(payload);
    }
  }

  return (
    <div>
      <PageHeader
        title="Quản lý nguyên liệu"
        description="Tìm kiếm, thêm, sửa và xóa nguyên liệu"
        action={<Button onClick={() => { setEditing(null); setFormOpen(true); }}>Thêm nguyên liệu</Button>}
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
        onSubmit={(e) => { e.preventDefault(); search(filters); }}
        className="mb-4 grid gap-3 rounded-2xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950 sm:grid-cols-3"
      >
        <Input
          label="Từ khóa"
          value={filters.keyword ?? ""}
          onChange={(e) => setFilters((c) => ({ ...c, keyword: e.target.value }))}
        />
        <Input
          label="Danh mục"
          value={filters.category ?? ""}
          onChange={(e) => setFilters((c) => ({ ...c, category: e.target.value }))}
        />
        <div className="flex items-end gap-2">
          <Button type="submit" loading={loading}>Tìm kiếm</Button>
          <Button
            type="button"
            variant="secondary"
            onClick={() => {
              setFilters(defaultIngredientFilters);
              search(defaultIngredientFilters);
            }}
          >
            Xóa bộ lọc
          </Button>
        </div>
      </form>

      <p className="mb-3 text-sm text-zinc-500">Tìm thấy {totalCount} nguyên liệu</p>

      <div className="overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Nguyên liệu</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Danh mục</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Đơn vị</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Calories</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Giá</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">Trạng thái</th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">Đang tải...</td></tr>
              ) : ingredients.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-sm text-zinc-500">Không có nguyên liệu nào.</td></tr>
              ) : (
                ingredients.map((item) => {
                  const isBusy =
                    actionLoadingId === item.id || detailLoadingId === item.id;
                  return (
                    <tr key={item.id} className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40">
                      <td className="px-4 py-4">
                        <div className="font-medium text-zinc-900 dark:text-zinc-50">{item.nameVi}</div>
                        {item.nameEn ? <div className="text-sm text-zinc-500">{item.nameEn}</div> : null}
                      </td>
                      <td className="px-4 py-4 text-sm">{item.category ? translateData(item.category) : "—"}</td>
                      <td className="px-4 py-4 text-sm">{item.unitDefault || "—"}</td>
                      <td className="px-4 py-4 text-sm">{formatNumber(item.caloriesKcal)}</td>
                      <td className="px-4 py-4 text-sm">{formatVnd(item.estimatedPriceVnd)}</td>
                      <td className="px-4 py-4">
                        <Badge variant={item.isActive ? "success" : "danger"}>
                          {item.isActive ? "Hoạt động" : "Ẩn"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex justify-end gap-2">
                          <Button variant="secondary" className="h-9 px-3 text-xs" disabled={isBusy} loading={detailLoadingId === item.id} onClick={() => openEdit(item)}>Sửa</Button>
                          <Button variant="danger" className="h-9 px-3 text-xs" loading={isBusy} onClick={() => setDeleting(item)}>Xóa</Button>
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

      <IngredientFormDialog
        open={formOpen}
        ingredient={editing}
        loading={saving}
        onClose={() => { setFormOpen(false); setEditing(null); }}
        onSubmit={handleFormSubmit}
      />

      {deleting ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
            <h2 className="text-lg font-semibold">Xóa nguyên liệu</h2>
            <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
              Bạn có chắc muốn xóa <span className="font-medium">{deleting.nameVi}</span>?
            </p>
            <div className="mt-6 flex justify-end gap-3">
              <Button variant="secondary" onClick={() => setDeleting(null)} disabled={Boolean(actionLoadingId)}>Hủy</Button>
              <Button variant="danger" loading={actionLoadingId === deleting.id} onClick={async () => { await deleteIngredient(deleting); setDeleting(null); }}>Xóa</Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
