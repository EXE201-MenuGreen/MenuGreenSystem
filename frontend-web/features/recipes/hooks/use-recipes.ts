"use client";

import { useCallback, useEffect, useState } from "react";
import { recipeApi } from "@/features/recipes/api/recipe-api";
import type {
  Recipe,
  RecipeSearchParams,
  RecipeUpsertRequest,
} from "@/features/recipes/types";
import { getErrorMessage } from "@/lib/api/errors";

export const defaultRecipeFilters: RecipeSearchParams = {
  keyword: "",
  mealType: "",
  difficulty: "",
};

function buildSearchQuery(params: RecipeSearchParams) {
  return {
    keyword: params.keyword || undefined,
    mealType: params.mealType || undefined,
    difficulty: params.difficulty || undefined,
    isActive: params.isActive,
  };
}

export function useRecipes() {
  const [filters, setFilters] = useState<RecipeSearchParams>(
    defaultRecipeFilters,
  );
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const search = useCallback(
    async (params: RecipeSearchParams = defaultRecipeFilters) => {
      setLoading(true);
      setError(null);

      try {
        const result = await recipeApi.search(buildSearchQuery(params));
        setRecipes(result.items);
        setTotalCount(result.totalCount);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tải danh sách công thức"));
      } finally {
        setLoading(false);
      }
    },
    [],
  );

  useEffect(() => {
    const timeoutId = window.setTimeout(() => search(defaultRecipeFilters), 0);
    return () => window.clearTimeout(timeoutId);
  }, [search]);

  const createRecipe = useCallback(
    async (payload: RecipeUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await recipeApi.create(payload);
        setNotice(`Đã tạo công thức "${payload.title}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tạo công thức"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, search],
  );

  const updateRecipe = useCallback(
    async (id: string, payload: RecipeUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        await recipeApi.update(id, payload);
        setNotice(`Đã cập nhật công thức "${payload.title}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật công thức"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, search],
  );

  const deleteRecipe = useCallback(
    async (recipe: Recipe) => {
      setActionLoadingId(recipe.id);
      setNotice(null);
      setError(null);

      try {
        await recipeApi.delete(recipe.id);
        setNotice(`Đã xóa công thức "${recipe.title}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xóa công thức"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [filters, search],
  );

  const loadRecipeDetail = useCallback(async (id: string) => {
    return recipeApi.getById(id);
  }, []);

  return {
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
  };
}
