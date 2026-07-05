"use client";

import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/layout/page-header";
import { useAiAdmin } from "@/features/ai-assistant/hooks/use-ai-admin";
import { formatDateTime, formatNumber } from "@/lib/utils/format";

function StatCard({
  label,
  value,
  helper,
  loading,
}: {
  label: string;
  value: string;
  helper: string;
  loading: boolean;
}) {
  return (
    <div className="rounded-3xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950">
      <p className="text-sm text-zinc-500 dark:text-zinc-400">{label}</p>
      <p className="mt-2 text-3xl font-semibold text-zinc-900 dark:text-zinc-50">
        {loading ? "..." : value}
      </p>
      <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">{helper}</p>
    </div>
  );
}

export function AiAdminManagement() {
  const { overview, loading, error, reload } = useAiAdmin();
  const bridgeHealth = overview?.bridgeHealth;
  const workerHealthy = Boolean(bridgeHealth?.workerReachable);

  return (
    <div>
      <PageHeader
        title="AI Assistant"
        description="Theo doi cau noi giua backend MenuGreenSystem va runtime RAG_AI_MenuGreen."
        action={
          <div className="flex gap-2">
            <Link href="/ai-coach">
              <Button variant="secondary">Mo giao dien user</Button>
            </Link>
            <Button variant="secondary" onClick={() => reload()} loading={loading}>
              Lam moi
            </Button>
          </div>
        }
      />

      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <div className="mb-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="AI profiles"
          value={formatNumber(overview?.totalAiProfiles)}
          helper="User co ho so AI rieng trong DB."
          loading={loading}
        />
        <StatCard
          label="Conversations"
          value={formatNumber(overview?.totalConversations)}
          helper="Tong so hoi thoai da luu."
          loading={loading}
        />
        <StatCard
          label="Messages"
          value={formatNumber(overview?.totalMessages)}
          helper="Tong so tin nhan user va assistant."
          loading={loading}
        />
        <StatCard
          label="Messages 7 ngay"
          value={formatNumber(overview?.messagesLast7Days)}
          helper="Dung de nhin tan suat su dung AI gan day."
          loading={loading}
        />
      </div>

      <div className="mb-6 grid gap-6 xl:grid-cols-[1.1fr_1.4fr]">
        <section className="rounded-[28px] border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
                Bridge Health
              </h2>
              <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                Kiem tra runtime AI co reachable tu backend .NET hay khong.
              </p>
            </div>
            <Badge variant={workerHealthy ? "success" : "warning"}>
              {workerHealthy ? "Healthy" : "Needs attention"}
            </Badge>
          </div>

          <dl className="mt-6 space-y-4 text-sm">
            <div>
              <dt className="text-zinc-500 dark:text-zinc-400">Worker URL</dt>
              <dd className="mt-1 break-all font-medium text-zinc-900 dark:text-zinc-50">
                {bridgeHealth?.workerUrl || "Chua cau hinh"}
              </dd>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <dt className="text-zinc-500 dark:text-zinc-400">Configured</dt>
                <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                  {bridgeHealth?.workerConfigured ? "Yes" : "Fallback/default"}
                </dd>
              </div>
              <div>
                <dt className="text-zinc-500 dark:text-zinc-400">Status code</dt>
                <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                  {bridgeHealth?.statusCode ?? "—"}
                </dd>
              </div>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <dt className="text-zinc-500 dark:text-zinc-400">Service</dt>
                <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                  {bridgeHealth?.workerService || "Unknown"}
                </dd>
              </div>
              <div>
                <dt className="text-zinc-500 dark:text-zinc-400">Checked at</dt>
                <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                  {formatDateTime(bridgeHealth?.checkedAt)}
                </dd>
              </div>
            </div>
            {bridgeHealth?.error ? (
              <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-amber-800 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-300">
                {bridgeHealth.error}
              </div>
            ) : null}
          </dl>
        </section>

        <section className="rounded-[28px] border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
                Integration Notes
              </h2>
              <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                Tom tat cach MenuGreenSystem dang dung AI runtime.
              </p>
            </div>
          </div>

          <div className="mt-6 grid gap-4">
            <div className="rounded-2xl bg-emerald-50 p-4 dark:bg-emerald-950/30">
              <p className="text-sm font-medium text-emerald-800 dark:text-emerald-300">
                Business state o backend chinh
              </p>
              <p className="mt-2 text-sm leading-6 text-emerald-900/90 dark:text-emerald-100/90">
                Meal log, meal plan, profile, allergy va lich su AI van nam o
                MenuGreenSystem. Runtime AI chi dong vai tro xu ly hoi dap va
                recommendation logic nang.
              </p>
            </div>
            <div className="rounded-2xl bg-sky-50 p-4 dark:bg-sky-950/30">
              <p className="text-sm font-medium text-sky-800 dark:text-sky-300">
                Contract da duoc can chinh
              </p>
              <p className="mt-2 text-sm leading-6 text-sky-900/90 dark:text-sky-100/90">
                Backend hien gui dung payload ma runtime can: message, user_id,
                thread_id, request_id va conversation_history.
              </p>
            </div>
            <div className="rounded-2xl bg-zinc-100 p-4 dark:bg-zinc-900">
              <p className="text-sm font-medium text-zinc-800 dark:text-zinc-200">
                Muc tieu tiep theo
              </p>
              <p className="mt-2 text-sm leading-6 text-zinc-700 dark:text-zinc-300">
                Khi mobile backend can dung AI, no nen goi MenuGreenSystem API
                thay vi goi truc tiep runtime, de giu duoc auth, meal state va
                audit log o mot noi.
              </p>
            </div>
          </div>
        </section>
      </div>

      <section className="overflow-hidden rounded-[28px] border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="border-b border-zinc-200 px-6 py-5 dark:border-zinc-800">
          <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Recent Conversations
          </h2>
          <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            Kiem tra nhanh noi dung, tan suat va do dai hoi thoai AI.
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Conversation
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Preview
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Messages
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Last activity
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-sm text-zinc-500">
                    Dang tai du lieu AI...
                  </td>
                </tr>
              ) : !overview?.recentConversations.length ? (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-sm text-zinc-500">
                    Chua co conversation nao.
                  </td>
                </tr>
              ) : (
                overview.recentConversations.map((conversation) => (
                  <tr key={conversation.conversationId} className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40">
                    <td className="px-4 py-4">
                      <div className="font-medium text-zinc-900 dark:text-zinc-50">
                        {conversation.title}
                      </div>
                      <div className="mt-1 text-xs text-zinc-500">
                        {conversation.conversationId}
                      </div>
                    </td>
                    <td className="max-w-xl px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                      {conversation.lastMessagePreview || "Khong co preview"}
                    </td>
                    <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                      {formatNumber(conversation.messageCount)}
                    </td>
                    <td className="px-4 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                      {formatDateTime(conversation.lastMessageAt)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
