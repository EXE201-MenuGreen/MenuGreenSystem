"use client";

import { useCallback, useEffect, useState } from "react";
import { adminUserApi } from "@/features/users/api/admin-user-api";
import { userApi } from "@/features/users/api/user-api";
import type { UserAdmin } from "@/features/users/types";
import { getErrorMessage } from "@/lib/api/errors";

export function useUsers() {
  const [users, setUsers] = useState<UserAdmin[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await adminUserApi.getAll();
      setUsers(data);
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải danh sách người dùng"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timeoutId = window.setTimeout(reload, 0);
    return () => window.clearTimeout(timeoutId);
  }, [reload]);

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
