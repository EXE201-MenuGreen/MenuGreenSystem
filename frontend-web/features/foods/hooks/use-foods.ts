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

function buildSearchQuery(params: FoodSearchParams, page: number, pageSize: number) {
  return {
    keyword: params.keyword || undefined,
    category: params.category || undefined,
    proteinLevel: params.proteinLevel || undefined,
    minCalories: params.minCalories,
    maxCalories: params.maxCalories,
    maxPriceVnd: params.maxPriceVnd,
    maxPrepTimeMin: params.maxPrepTimeMin,
    page,
    pageSize,
  };
}

export function useFoods() {
  const [filters, setFilters] = useState<FoodSearchParams>(defaultFoodFilters);
  const [page, setPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [foods, setFoods] = useState<Food[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const search = useCallback(
    async (
      params: FoodSearchParams = defaultFoodFilters,
      targetPage: number = 1,
      targetPageSize: number = 10,
    ) => {
      setLoading(true);
      setError(null);

      try {
        const query = buildSearchQuery(params, targetPage, targetPageSize);
        const result = await foodApi.search(query);
        setFoods(result.items);
        setTotalCount(result.totalCount);
        setPage(result.page ?? targetPage);
        setPageSize(result.pageSize ?? targetPageSize);
        const calculatedTotalPages =
          result.totalPages ??
          (result.pageSize && result.pageSize > 0
            ? Math.ceil(result.totalCount / result.pageSize)
            : 1);
        setTotalPages(Math.max(1, calculatedTotalPages));
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tải danh sách món ăn"));
      } finally {
        setLoading(false);
      }
    },
    [],
  );

  // Initial load
  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      search(defaultFoodFilters, 1, 10);
    }, 0);
    return () => window.clearTimeout(timeoutId);
  }, [search]);

  const handlePageChange = useCallback(
    (newPage: number) => {
      setPage(newPage);
      search(filters, newPage, pageSize);
    },
    [filters, pageSize, search],
  );

  const handlePageSizeChange = useCallback(
    (newPageSize: number) => {
      setPageSize(newPageSize);
      setPage(1);
      search(filters, 1, newPageSize);
    },
    [filters, search],
  );

  const handleFilterSubmit = useCallback(
    (newFilters: FoodSearchParams) => {
      setFilters(newFilters);
      setPage(1);
      search(newFilters, 1, pageSize);
    },
    [pageSize, search],
  );

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
        await search(filters, page, pageSize);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể tạo món ăn"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, page, pageSize, search],
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
        await search(filters, page, pageSize);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật món ăn"));
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [filters, page, pageSize, search],
  );

  const deleteFood = useCallback(
    async (food: Food) => {
      setActionLoadingId(food.id);
      setNotice(null);
      setError(null);

      try {
        await foodApi.delete(food.id);
        setNotice(`Đã xóa món "${food.nameVi}".`);
        // If current page is now empty and not page 1, shift back one page
        const newTotalCount = totalCount - 1;
        const newMaxPage = Math.max(1, Math.ceil(newTotalCount / pageSize));
        const targetPage = page > newMaxPage ? newMaxPage : page;
        await search(filters, targetPage, pageSize);
      } catch (err) {
        setError(getErrorMessage(err, "Không thể xóa món ăn"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [filters, page, pageSize, search, totalCount],
  );

  const loadFoodDetail = useCallback(async (id: string) => {
    return foodApi.getById(id);
  }, []);

  return {
    filters,
    setFilters,
    page,
    pageSize,
    totalPages,
    setPage: handlePageChange,
    setPageSize: handlePageSizeChange,
    handleFilterSubmit,
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
