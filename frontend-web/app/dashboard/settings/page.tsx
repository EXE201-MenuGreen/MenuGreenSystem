"use client";

import { PageHeader } from "@/components/layout/page-header";
import { useAuthActions } from "@/features/auth/hooks/use-auth";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AlertCircle } from "lucide-react";

export default function SettingsPage() {
  const { logout } = useAuthActions();
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handlePasswordChange(event: React.FormEvent) {
    event.preventDefault();
    setError(null);
    setSuccess(false);

    if (newPassword !== confirmPassword) {
      setError("Mật khẩu mới không khớp.");
      return;
    }

    if (newPassword.length < 6) {
      setError("Mật khẩu mới phải ít nhất 6 ký tự.");
      return;
    }

    setLoading(true);
    try {
      // TODO: Call backend API to change password
      // await authApi.changePassword({ currentPassword, newPassword });
      setSuccess(true);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Đổi mật khẩu thất bại.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Cài đặt"
        description="Quản lý mật khẩu và cấu hình hệ thống"
      />

      <div className="mt-6 space-y-6">
        {/* Password Change */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h2 className="text-lg font-semibold">Đổi mật khẩu</h2>
          <p className="mt-1 text-sm text-zinc-500">
            Cập nhật mật khẩu của bạn để bảo mật tài khoản
          </p>

          <form onSubmit={handlePasswordChange} className="mt-6 space-y-4">
            {error && (
              <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
                <AlertCircle className="h-4 w-4" />
                {error}
              </div>
            )}
            {success && (
              <div className="rounded-lg border border-green-200 bg-green-50 p-3 text-sm text-green-700 dark:border-green-900 dark:bg-green-950/30 dark:text-green-300">
                Đổi mật khẩu thành công!
              </div>
            )}

            <Input
              label="Mật khẩu hiện tại"
              type="password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              required
            />
            <Input
              label="Mật khẩu mới"
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
            />
            <Input
              label="Xác nhận mật khẩu mới"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
            <Button type="submit" loading={loading}>
              Cập nhật mật khẩu
            </Button>
          </form>
        </div>

        {/* Logout */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h2 className="text-lg font-semibold">Đăng xuất</h2>
          <p className="mt-1 text-sm text-zinc-500">
            Đăng xuất khỏi tài khoản quản trị
          </p>
          <Button
            variant="danger"
            className="mt-4"
            onClick={() => logout()}
            loading={false}
          >
            Đăng xuất
          </Button>
        </div>
      </div>
    </div>
  );
}
