"use client";

import { useCallback, useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/layout/page-header";
import { migrationApi } from "@/features/migrations/api/admin-migration-api";
import { getErrorMessage } from "@/lib/api/errors";

export function AdminMigrationPanel() {
  const [status, setStatus] = useState<{
    gitSha: string;
    dataAccessLayerVersion: string;
    applied: string[];
    pending: string[];
  } | null>(null);
  const [history, setHistory] = useState<Array<{
    migrationId: string;
    productVersion: string;
    applied: Date | null;
  }>>([]);
  const [loading, setLoading] = useState(true);
  const [applying, setApplying] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [applyMessage, setApplyMessage] = useState<string | null>(null);

  const fetchStatus = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await migrationApi.getStatus();
      setStatus(data);
    } catch (err) {
      setError(getErrorMessage(err, "Khong the tai trang thai migration"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStatus();
  }, [fetchStatus]);

  async function handleApply() {
    setApplying(true);
    setApplyMessage(null);
    setError(null);
    try {
      const result = await migrationApi.apply();
      setApplyMessage(result.message);
      await fetchStatus();
    } catch (err) {
      setError(getErrorMessage(err, "Apply migration that bai"));
    } finally {
      setApplying(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Di chuyển cơ sở dữ liệu"
        description="Quản lý EF Core migrations và trạng thái database"
        action={
          <div className="flex gap-2">
            <Button variant="secondary" onClick={fetchStatus} loading={loading}>
              Làm mới
            </Button>
            <Button onClick={handleApply} loading={applying} variant="danger">
              Áp dụng
            </Button>
          </div>
        }
      />

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      )}

      {applyMessage && (
        <div className="mb-4 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-900 dark:bg-green-950/30 dark:text-green-300">
          {applyMessage}
        </div>
      )}

      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950">
          <p className="text-sm text-zinc-500 dark:text-zinc-400">Git SHA</p>
          <p className="mt-1 break-all font-mono text-sm">{status?.gitSha || "—"}</p>
        </div>
        <div className="rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950">
          <p className="text-sm text-zinc-500 dark:text-zinc-400">DAL Version</p>
          <p className="mt-1 font-mono text-sm">{status?.dataAccessLayerVersion || "—"}</p>
        </div>
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-50">
            Đã áp dụng ({status?.applied.length ?? 0})
          </h2>
          <div className="mt-4 max-h-64 space-y-2 overflow-y-auto">
            {status?.applied.map((m) => (
              <div
                key={m}
                className="rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700 dark:bg-green-950/30 dark:text-green-400"
              >
                {m}
              </div>
            ))}
            {!status?.applied.length && (
              <p className="text-sm text-zinc-500">Chua co migration nao duoc apply.</p>
            )}
          </div>
        </div>

        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-50">
            Đang chờ áp dụng ({status?.pending.length ?? 0})
          </h2>
          <div className="mt-4 max-h-64 space-y-2 overflow-y-auto">
            {status?.pending.map((m) => (
              <div
                key={m}
                className="rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-700 dark:bg-amber-950/30 dark:text-amber-400"
              >
                {m}
              </div>
            ))}
            {!status?.pending.length && (
              <p className="text-sm text-zinc-500">Khong co migration cho.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
