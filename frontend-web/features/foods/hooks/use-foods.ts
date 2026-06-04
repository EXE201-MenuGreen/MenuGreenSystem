"use client";

import { useCallback, useEffect, useState } from "react";
import { foodApi } from "@/features/foods/api/food-api";
import type {
  Food,
  FoodSearchParams,
  FoodUpsertRequest,
} from "@/features/foods/types";
import { getErrorMessage } from "@/lib/api/errors";

export const defaultFoodFilters: FoodSearchParams = {
  keyword: "",
  category: "",
  proteinLevel: "",
};

function buildSearchQuery(params: FoodSearchParams) {
  return {
    keyword: params.keyword || undefined,
    category: params.category || undefined,
    proteinLevel: params.proteinLevel || undefined,
    minCalories: params.minCalories,
    maxCalories: params.maxCalories,
    maxPriceVnd: params.maxPriceVnd,
    maxPrepTimeMin: params.maxPrepTimeMin,
  };
}

export function useFoods() {
  const [filters, setFilters] = useState<FoodSearchParams>(defaultFoodFilters);
  const [foods, setFoods] = useState<Food[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const search = useCallback(async (params: FoodSearchParams = defaultFoodFilters) => {
    setLoading(true);
    setError(null);

    try {
      const result = await foodApi.search(buildSearchQuery(params));
      setFoods(result.items);
      setTotalCount(result.totalCount);
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải danh sách món ăn"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    search(defaultFoodFilters);
  }, [search]);

  const createFood = useCallback(
    async (payload: FoodUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        const { allergenKeys, ...upsert } = payload;
        const created = await foodApi.create(upsert);
        await foodApi.setAllergenTags(created.id, allergenKeys ?? []);
        setNotice(`Đã tạo món "${payload.nameVi}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tạo món ăn"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, search],
  );

  const updateFood = useCallback(
    async (id: string, payload: FoodUpsertRequest) => {
      setSaving(true);
      setNotice(null);
      setError(null);

      try {
        const { allergenKeys, ...upsert } = payload;
        await foodApi.update(id, upsert);
        await foodApi.setAllergenTags(id, allergenKeys ?? []);
        setNotice(`Đã cập nhật món "${payload.nameVi}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật món ăn"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, search],
  );

  const deleteFood = useCallback(
    async (food: Food) => {
      setActionLoadingId(food.id);
      setNotice(null);
      setError(null);

      try {
        await foodApi.delete(food.id);
        setNotice(`Đã xóa món "${food.nameVi}".`);
        await search(filters);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xóa món ăn"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [filters, search],
  );

  const loadFoodDetail = useCallback(async (id: string) => {
    return foodApi.getById(id);
  }, []);

  return {
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
  };
}
