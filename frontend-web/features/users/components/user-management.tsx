"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge, roleBadgeVariant } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Pagination } from "@/components/ui/pagination";
import { PageHeader } from "@/components/layout/page-header";
import { AssignRoleDialog } from "@/features/users/components/assign-role-dialog";
import { ManageMembershipDialog } from "@/features/users/components/manage-membership-dialog";
import { useUsers, defaultUserFilters } from "@/features/users/hooks/use-users";
import type { UserAdmin } from "@/features/users/types";
import { formatDateTime } from "@/lib/utils/format";

const membershipStatusLabels: Record<string, string> = {
  nosubscription: "Chưa đăng ký",
  scheduled: "Đã lên lịch",
  pendingpayment: "Chờ thanh toán",
  expired: "Đã hết hạn",
  cancelled: "Đã thu hồi",
};

function getMembershipLabel(user: UserAdmin) {
  const status = user.membershipStatus.toLowerCase();
  if (status === "active") {
    return user.membershipTier === "free" ? "Quyền cơ bản" : user.membershipTier;
  }
  return membershipStatusLabels[status] ?? user.membershipStatus;
}

export function UserManagement() {
  const {
    filters,
    setFilters,
    page,
    pageSize,
    totalPages,
    totalCount,
    setPage,
    setPageSize,
    handleFilterSubmit,
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
  const [membershipUser, setMembershipUser] = useState<UserAdmin | null>(null);

  async function handleAssignRole(user: UserAdmin, role: string) {
    await assignRole(user, role);
    setSelectedUser(null);
  }

  function handleSearchSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    handleFilterSubmit(filters);
  }

  return (
    <div>
      <PageHeader
        title="Quản lý người dùng"
        description="Quản lý độc lập role tài khoản, phân quyền và gói tính năng của thành viên"
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

      {/* Filter and Search Form */}
      <form
        onSubmit={handleSearchSubmit}
        className="mb-4 grid gap-3 rounded-2xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950 sm:grid-cols-2 lg:grid-cols-4"
      >
        <Input
          label="Tìm kiếm"
          placeholder="Email, họ tên..."
          value={filters.keyword ?? ""}
          onChange={(e) =>
            setFilters((current) => ({ ...current, keyword: e.target.value }))
          }
        />
        <Select
          label="Vai trò (Role)"
          value={filters.role ?? ""}
          onChange={(e) =>
            setFilters((current) => ({
              ...current,
              role: e.target.value,
            }))
          }
        >
          <option value="">Tất cả vai trò</option>
          <option value="Admin">Admin</option>
          <option value="Coach">Coach</option>
          <option value="User">User</option>
        </Select>
        <Select
          label="Trạng thái tài khoản"
          value={String(filters.isActive ?? "")}
          onChange={(e) =>
            setFilters((current) => ({
              ...current,
              isActive: e.target.value,
            }))
          }
        >
          <option value="">Tất cả trạng thái</option>
          <option value="true">Hoạt động</option>
          <option value="false">Đã khóa</option>
        </Select>
        <div className="flex items-end gap-2">
          <Button type="submit" loading={loading} className="w-full sm:w-auto">
            Tìm kiếm
          </Button>
          <Button
            type="button"
            variant="secondary"
            className="w-full sm:w-auto"
            onClick={() => {
              setFilters(defaultUserFilters);
              handleFilterSubmit(defaultUserFilters);
            }}
          >
            Xóa bộ lọc
          </Button>
        </div>
      </form>

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
                  Gói thành viên
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
                    colSpan={8}
                    className="px-4 py-10 text-center text-sm text-zinc-500"
                  >
                    Đang tải danh sách...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td
                    colSpan={8}
                    className="px-4 py-10 text-center text-sm text-zinc-500"
                  >
                    Không có người dùng nào.
                  </td>
                </tr>
              ) : (
                users.map((user) => {
                  const isBusy = actionLoadingId === user.id;
                  const hasSubscription =
                    user.membershipStatus.toLowerCase() !== "nosubscription";

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
                        <div className="flex flex-col items-start gap-1">
                          <Badge
                            variant={
                              user.membershipStatus.toLowerCase() === "active"
                                ? "success"
                                : "neutral"
                            }
                          >
                            {getMembershipLabel(user)}
                          </Badge>
                          <span className="text-xs text-zinc-500">
                            {!hasSubscription
                              ? "Quyền cơ bản: free_features"
                              : user.membershipExpiresAt
                              ? `Hết hạn ${formatDateTime(user.membershipExpiresAt)}`
                              : user.membershipStatus}
                          </span>
                        </div>
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
                            onClick={() => setMembershipUser(user)}
                          >
                            Quản lý gói
                          </Button>
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

        {/* Pagination Controls */}
        <Pagination
          page={page}
          pageSize={pageSize}
          totalCount={totalCount}
          totalPages={totalPages}
          onPageChange={setPage}
          onPageSizeChange={setPageSize}
          itemName="người dùng"
          disabled={loading}
        />
      </div>

      <AssignRoleDialog
        key={selectedUser?.id ?? "closed"}
        user={selectedUser}
        loading={Boolean(selectedUser && actionLoadingId === selectedUser.id)}
        onClose={() => setSelectedUser(null)}
        onConfirm={handleAssignRole}
      />
      <ManageMembershipDialog
        key={membershipUser?.id ?? "membership-closed"}
        user={membershipUser}
        onClose={() => setMembershipUser(null)}
        onChanged={reload}
      />
    </div>
  );
}
