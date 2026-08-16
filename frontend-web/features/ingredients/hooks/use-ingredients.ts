"use client";

import { useCallback, useEffect, useState } from "react";
import { ingredientApi } from "@/features/ingredients/api/ingredient-api";
import type {
  Ingredient,
  IngredientSearchParams,
  IngredientUpsertRequest,
} from "@/features/ingredients/types";
import { getErrorMessage } from "@/lib/api/errors";

export const defaultIngredientFilters: IngredientSearchParams = {
  keyword: "",
  category: "",
};

function buildSearchQuery(params: IngredientSearchParams) {
  return {
    keyword: params.keyword || undefined,
    category: params.category || undefined,
    isActive: params.isActive,
  };
}

export function useIngredients() {
  const [filters, setFilters] = useState<IngredientSearchParams>(
    defaultIngredientFilters,
  );
  const [ingredients, setIngredients] = useState<Ingredient[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const search = useCallback(
    async (params: IngredientSearchParams = defaultIngredientFilters) => {
      setLoading(true);
      setError(null);

      try {
        const result = await ingredientApi.search(buildSearchQuery(params));
        setIngredients(result.items);
        setTotalCount(result.totalCount);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tải danh sách nguyên liệu"));
      } finally {
        setLoading(false);
      }
    },
    [],
  );

  useEffect(() => {
    const timeoutId = window.setTimeout(
      () => search(defaultIngredientFilters),
      0,
    );
    return () => window.clearTimeout(timeoutId);
  }, [search]);

  const createIngredient = useCallback(
    async (payload: IngredientUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await ingredientApi.create(payload);
        setNotice(`Đã tạo nguyên liệu "${payload.nameVi}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tạo nguyên liệu"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, search],
  );

  const updateIngredient = useCallback(
    async (id: string, payload: IngredientUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await ingredientApi.update(id, payload);
        setNotice(`Đã cập nhật nguyên liệu "${payload.nameVi}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật nguyên liệu"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, search],
  );

  const deleteIngredient = useCallback(
    async (ingredient: Ingredient) => {
      setActionLoadingId(ingredient.id);
      setNotice(null);
      setError(null);

      try {
        await ingredientApi.delete(ingredient.id);
        setNotice(`Đã xóa nguyên liệu "${ingredient.nameVi}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xóa nguyên liệu"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [filters, search],
  );

  const loadIngredientDetail = useCallback(async (id: string) => {
    return ingredientApi.getById(id);
  }, []);

  return {
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
  };
}
