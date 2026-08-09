"use client";

import { useAuth } from "@/features/auth/hooks/use-auth";
import { PageHeader } from "@/components/layout/page-header";

export default function ProfilePage() {
  const { fullName, role } = useAuth();

  return (
    <div>
      <PageHeader
        title="Hồ sơ"
        description="Thông tin tài khoản quản trị viên"
      />

      <div className="mt-6 rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
        <div className="space-y-4">
          <div>
            <p className="text-sm text-zinc-500">Họ tên</p>
            <p className="mt-1 text-lg font-medium">{fullName || "—"}</p>
          </div>
          <div>
            <p className="text-sm text-zinc-500">Vai trò</p>
            <p className="mt-1 text-lg font-medium">{role || "Admin"}</p>
          </div>
          <div>
            <p className="text-sm text-zinc-500">Trạng thái</p>
            <p className="mt-1">
              <span className="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-400">
                Hoạt động
              </span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
