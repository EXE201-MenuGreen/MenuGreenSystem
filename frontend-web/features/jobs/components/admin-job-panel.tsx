"use client";

import { useCallback, useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/layout/page-header";
import { jobApi, type JobTriggerResult } from "@/features/jobs/api/admin-job-api";
import { getErrorMessage } from "@/lib/api/errors";
import { formatDateTime } from "@/lib/utils/format";

const AVAILABLE_JOBS = [
  { name: "SubscriptionExpiration", description: "Kiem tra va xu ly cac goi subscription het han" },
  { name: "StreakReset", description: "Reset streak cho nhung nguoi dung khong con active" },
  { name: "GoalDrift", description: "Phat hien va thong bao khi nguoi dung cham dut muc tieu" },
  { name: "SepayReconciliation", description: "Dong bo trang thai thanh toan SePay" },
  { name: "DailyStarter", description: "Tao daily starter cho tat ca nguoi dung" },
];

interface JobLog {
  jobName: string;
  triggeredAt: string;
  message: string;
  success: boolean;
}

export function AdminJobPanel() {
  const [triggering, setTriggering] = useState<string | null>(null);
  const [logs, setLogs] = useState<JobLog[]>([]);
  const [error, setError] = useState<string | null>(null);

  async function handleTrigger(jobName: string) {
    setTriggering(jobName);
    setError(null);
    try {
      const result: JobTriggerResult = await jobApi.trigger(jobName);
      setLogs((prev) => [
        {
          jobName,
          triggeredAt: result.triggeredAt || new Date().toISOString(),
          message: result.message,
          success: true,
        },
        ...prev,
      ]);
    } catch (err) {
      const msg = getErrorMessage(err, "Trigger job that bai");
      setError(msg);
      setLogs((prev) => [
        {
          jobName,
          triggeredAt: new Date().toISOString(),
          message: msg,
          success: false,
        },
        ...prev,
      ]);
    } finally {
      setTriggering(null);
    }
  }

  return (
    <div>
      <PageHeader
        title="Job Trigger"
        description="Kich hoat thu cong cac background job de kiem tra hoac xu ly ngay"
      />

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      )}

      <div className="mt-6 space-y-4">
        {AVAILABLE_JOBS.map((job) => (
          <div
            key={job.name}
            className="flex items-center justify-between rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950"
          >
            <div>
              <p className="font-medium text-zinc-900 dark:text-zinc-50">
                {job.name}
              </p>
              <p className="mt-1 text-sm text-zinc-500">{job.description}</p>
            </div>
            <Button
              variant="secondary"
              onClick={() => handleTrigger(job.name)}
              loading={triggering === job.name}
            >
              Trigger
            </Button>
          </div>
        ))}
      </div>

      {logs.length > 0 && (
        <div className="mt-8">
          <h2 className="mb-4 text-lg font-semibold">Job Logs</h2>
          <div className="space-y-2">
            {logs.map((log, i) => (
              <div
                key={i}
                className="flex items-start justify-between rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950"
              >
                <div>
                  <p className="font-medium text-zinc-900 dark:text-zinc-50">
                    {log.jobName}
                  </p>
                  <p className="mt-1 text-sm text-zinc-500">{log.message}</p>
                  <p className="mt-1 text-xs text-zinc-400">
                    {formatDateTime(log.triggeredAt)}
                  </p>
                </div>
                <span
                  className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    log.success
                      ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                      : "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
                  }`}
                >
                  {log.success ? "Success" : "Failed"}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
