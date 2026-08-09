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
      setError("Mat khau moi khong khop.");
      return;
    }

    if (newPassword.length < 6) {
      setError("Mat khau moi phai it nhat 6 ky tu.");
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
      setError(err instanceof Error ? err.message : "Doi mat khau that bai.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Cai dat"
        description="Quan ly mat khau va cau hinh he thong"
      />

      <div className="mt-6 space-y-6">
        {/* Password Change */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h2 className="text-lg font-semibold">Doi mat khau</h2>
          <p className="mt-1 text-sm text-zinc-500">
            Cap nhat mat khau cua ban de bao mat tai khoan
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
                Doi mat khau thanh cong!
              </div>
            )}

            <Input
              label="Mat khau hien tai"
              type="password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              required
            />
            <Input
              label="Mat khau moi"
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
            />
            <Input
              label="Xac nhan mat khau moi"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
            <Button type="submit" loading={loading}>
              Cap nhat mat khau
            </Button>
          </form>
        </div>

        {/* Logout */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h2 className="text-lg font-semibold">Dang xuat</h2>
          <p className="mt-1 text-sm text-zinc-500">
            Dang xuat khoi tai khoan quan tri
          </p>
          <Button
            variant="danger"
            className="mt-4"
            onClick={() => logout()}
            loading={false}
          >
            Dang xuat
          </Button>
        </div>
      </div>
    </div>
  );
}
