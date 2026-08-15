"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge, roleBadgeVariant } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/page-header";
import { AssignRoleDialog } from "@/features/users/components/assign-role-dialog";
import { useUsers } from "@/features/users/hooks/use-users";
import type { UserAdmin } from "@/features/users/types";
import { formatDateTime } from "@/lib/utils/format";

export function UserManagement() {
  const {
    users,
    loading,
    actionLoadingId,
    error,
    notice,
    reload,
    toggleStatus,
    assignRole,
  } = useUsers();

  const [selectedUser, setSelectedUser] = useState<UserAdmin | null>(null);

  async function handleAssignRole(user: UserAdmin, role: string) {
    await assignRole(user, role);
    setSelectedUser(null);
  }

  return (
    <div>
      <PageHeader
        title="Quản lý người dùng"
        description="Xem danh sách, bật/tắt trạng thái và gán role cho tài khoản"
        action={
          <Button variant="secondary" onClick={() => reload()} loading={loading}>
            Làm mới
          </Button>
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

      <div className="overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Người dùng
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Role
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Trạng thái
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Email xác thực
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Ngày tạo
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Đăng nhập cuối
                </th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Thao tác
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr>
                  <td
                    colSpan={7}
                    className="px-4 py-10 text-center text-sm text-zinc-500"
                  >
                    Đang tải danh sách...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td
                    colSpan={7}
                    className="px-4 py-10 text-center text-sm text-zinc-500"
                  >
                    Không có người dùng nào.
                  </td>
                </tr>
              ) : (
                users.map((user) => {
                  const isBusy = actionLoadingId === user.id;

                  return (
                    <tr
                      key={user.id}
                      className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40"
                    >
                      <td className="px-4 py-4">
                        <div className="font-medium text-zinc-900 dark:text-zinc-50">
                          {user.fullName || "—"}
                        </div>
                        <div className="text-sm text-zinc-500">{user.email}</div>
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant={roleBadgeVariant(user.role)}>
                          {user.role}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <Badge variant={user.isActive ? "success" : "danger"}>
                          {user.isActive ? "Hoạt động" : "Đã khóa"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4">
                        <Badge
                          variant={user.emailConfirmed ? "success" : "warning"}
                        >
                          {user.emailConfirmed ? "Đã xác thực" : "Chưa xác thực"}
                        </Badge>
                      </td>
                      <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                        {formatDateTime(user.createdAt)}
                      </td>
                      <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                        {formatDateTime(user.lastSignInAt)}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="secondary"
                            className="h-9 px-3 text-xs"
                            disabled={isBusy}
                            onClick={() => setSelectedUser(user)}
                          >
                            Gán role
                          </Button>
                          <Button
                            variant={user.isActive ? "danger" : "primary"}
                            className="h-9 px-3 text-xs"
                            loading={isBusy}
                            onClick={() => toggleStatus(user)}
                          >
                            {user.isActive ? "Khóa" : "Mở khóa"}
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

      <AssignRoleDialog
        key={selectedUser?.id ?? "closed"}
        user={selectedUser}
        loading={Boolean(selectedUser && actionLoadingId === selectedUser.id)}
        onClose={() => setSelectedUser(null)}
        onConfirm={handleAssignRole}
      />
    </div>
  );
}
