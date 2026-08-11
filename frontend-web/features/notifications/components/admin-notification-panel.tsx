"use client";

import { useCallback, useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/layout/page-header";
import { notificationAdminApi } from "@/features/notifications/api/admin-notification-api";
import { getErrorMessage } from "@/lib/api/errors";

export function AdminNotificationPanel() {
  const [stats, setStats] = useState<{
    pendingProcessed: number;
    sent: number;
    failed: number;
    skipped: number;
  } | null>(null);
  const [loading, setLoading] = useState(true);
  const [dispatching, setDispatching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dispatchMessage, setDispatchMessage] = useState<string | null>(null);

  const fetchStats = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await notificationAdminApi.getPendingStats();
      setStats(data);
    } catch (err) {
      setError(getErrorMessage(err, "Không thể tải thống kê thông báo"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  async function handleDispatch() {
    setDispatching(true);
    setDispatchMessage(null);
    setError(null);
    try {
      const result = await notificationAdminApi.dispatch();
      setDispatchMessage(result.message);
      await fetchStats();
    } catch (err) {
      setError(getErrorMessage(err, "Gửi thông báo thất bại"));
    } finally {
      setDispatching(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Gửi thông báo"
        description="Quản lý việc gửi notification đến người dùng"
        action={
          <div className="flex gap-2">
            <Button variant="secondary" onClick={fetchStats} loading={loading}>
              Làm mới
            </Button>
            <Button onClick={handleDispatch} loading={dispatching}>
              Gửi ngay
            </Button>
          </div>
        }
      />

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      )}

      {dispatchMessage && (
        <div className="mb-4 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-900 dark:bg-green-950/30 dark:text-green-300">
          {dispatchMessage}
        </div>
      )}

      <div className="mt-6 grid gap-4 sm:grid-cols-4">
        <StatCard label="Đã xử lý" value={stats?.pendingProcessed ?? 0} />
        <StatCard label="Đã gửi" value={stats?.sent ?? 0} />
        <StatCard label="Thất bại" value={stats?.failed ?? 0} />
        <StatCard label="Bỏ qua" value={stats?.skipped ?? 0} />
      </div>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950">
      <p className="text-sm text-zinc-500 dark:text-zinc-400">{label}</p>
      <p className="mt-2 text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        {value.toLocaleString()}
      </p>
    </div>
  );
}
