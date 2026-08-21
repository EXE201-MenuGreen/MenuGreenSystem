"use client";

import { useCallback, useEffect, useState } from "react";
import { adminUserApi } from "@/features/users/api/admin-user-api";
import { userApi } from "@/features/users/api/user-api";
import type { UserAdmin, UserSearchParams } from "@/features/users/types";
import { getErrorMessage } from "@/lib/api/errors";

export const defaultUserFilters: UserSearchParams = {
  keyword: "",
  role: "",
  isActive: "",
};

function buildUserSearchQuery(
  params: UserSearchParams,
  page: number,
  pageSize: number,
) {
  return {
    keyword: params.keyword || undefined,
    role: params.role || undefined,
    isActive:
      params.isActive === "true"
        ? true
        : params.isActive === "false"
        ? false
        : typeof params.isActive === "boolean"
        ? params.isActive
        : undefined,
    membershipStatus: params.membershipStatus || undefined,
    page,
    pageSize,
  };
}

export function useUsers() {
  const [filters, setFilters] = useState<UserSearchParams>(defaultUserFilters);
  const [page, setPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [users, setUsers] = useState<UserAdmin[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const search = useCallback(
    async (
      params: UserSearchParams = defaultUserFilters,
      targetPage: number = 1,
      targetPageSize: number = 10,
    ) => {
      setLoading(true);
      setError(null);

      try {
        const query = buildUserSearchQuery(params, targetPage, targetPageSize);
        const result = await adminUserApi.search(query);
        setUsers(result.items);
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
        setError(getErrorMessage(err, "Không thể tải danh sách người dùng"));
      } finally {
        setLoading(false);
      }
    },
    [],
  );

  // Initial load
  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      search(defaultUserFilters, 1, 10);
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
    (newFilters: UserSearchParams) => {
      setFilters(newFilters);
      setPage(1);
      search(newFilters, 1, pageSize);
    },
    [pageSize, search],
  );

  const reload = useCallback(async () => {
    await search(filters, page, pageSize);
  }, [filters, page, pageSize, search]);

  const toggleStatus = useCallback(
    async (user: UserAdmin) => {
      setActionLoadingId(user.id);
      setNotice(null);
      setError(null);

      try {
        if (user.isActive) {
          await adminUserApi.lock(user.id);
        } else {
          await adminUserApi.unlock(user.id);
        }
        setNotice(
          `Đã cập nhật trạng thái của ${user.fullName || user.email}.`,
        );
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể cập nhật trạng thái"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [reload],
  );

  const assignRole = useCallback(
    async (user: UserAdmin, role: string) => {
      setActionLoadingId(user.id);
      setNotice(null);
      setError(null);

      try {
        await userApi.assignRole(user.id, { role });
        setNotice(`Đã gán role ${role} cho ${user.fullName || user.email}.`);
        await reload();
      } catch (err) {
        setError(getErrorMessage(err, "Không thể gán role"));
      } finally {
        setActionLoadingId(null);
      }
    },
    [reload],
  );

  return {
    filters,
    setFilters,
    page,
    pageSize,
    totalPages,
    totalCount,
    setPage: handlePageChange,
    setPageSize: handlePageSizeChange,
    handleFilterSubmit,
    users,
    loading,
    actionLoadingId,
    error,
    notice,
    setNotice,
    setError,
    reload,
    toggleStatus,
    assignRole,
  };
}
