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
        title="Trợ lý AI"
        description="Theo dõi kết nối giữa backend MenuGreenSystem và runtime RAG_AI_MenuGreen."
        action={
          <div className="flex gap-2">
            <Link href="/ai-coach">
              <Button variant="secondary">Mở giao diện người dùng</Button>
            </Link>
            <Button variant="secondary" onClick={() => reload()} loading={loading}>
              Làm mới
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
          label="Hồ sơ AI"
          value={formatNumber(overview?.totalAiProfiles)}
          helper="User có hồ sơ AI riêng trong DB."
          loading={loading}
        />
        <StatCard
          label="Cuộc trò chuyện"
          value={formatNumber(overview?.totalConversations)}
          helper="Tổng số hội thoại đã lưu."
          loading={loading}
        />
        <StatCard
          label="Tin nhắn"
          value={formatNumber(overview?.totalMessages)}
          helper="Tổng số tin nhắn user và assistant."
          loading={loading}
        />
        <StatCard
          label="Tin nhắn 7 ngày"
          value={formatNumber(overview?.messagesLast7Days)}
          helper="Dùng để nhìn tần suất sử dụng AI gần đây."
          loading={loading}
        />
      </div>

      <div className="mb-6 grid gap-6 xl:grid-cols-[1.1fr_1.4fr]">
        <section className="rounded-[28px] border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
                Tình trạng kết nối
              </h2>
              <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                Kiểm tra runtime AI có reachable từ backend .NET hay không.
              </p>
            </div>
            <Badge variant={workerHealthy ? "success" : "warning"}>
              {workerHealthy ? "Hoạt động" : "Cần chú ý"}
            </Badge>
          </div>

          <dl className="mt-6 space-y-4 text-sm">
            <div>
              <dt className="text-zinc-500 dark:text-zinc-400">URL Worker</dt>
              <dd className="mt-1 break-all font-medium text-zinc-900 dark:text-zinc-50">
                {bridgeHealth?.workerUrl || "Chưa cấu hình"}
              </dd>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <dt className="text-zinc-500 dark:text-zinc-400">Đã cấu hình</dt>
              <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                {bridgeHealth?.workerConfigured ? "Có" : "Fallback/mặc định"}
              </dd>
            </div>
            <div>
              <dt className="text-zinc-500 dark:text-zinc-400">Mã trạng thái</dt>
                <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                  {bridgeHealth?.statusCode ?? "—"}
                </dd>
              </div>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <dt className="text-zinc-500 dark:text-zinc-400">Dịch vụ</dt>
                  <dd className="mt-1 text-zinc-900 dark:text-zinc-50">
                    {bridgeHealth?.workerService || "Không xác định"}
                  </dd>
                </div>
                <div>
                  <dt className="text-zinc-500 dark:text-zinc-400">Kiểm tra lúc</dt>
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
                Ghi chú tích hợp
              </h2>
              <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                Tóm tắt cách MenuGreenSystem đang dùng AI runtime.
              </p>
            </div>
          </div>

          <div className="mt-6 grid gap-4">
            <div className="rounded-2xl bg-emerald-50 p-4 dark:bg-emerald-950/30">
              <p className="text-sm font-medium text-emerald-800 dark:text-emerald-300">
                Business state ở backend chính
              </p>
              <p className="mt-2 text-sm leading-6 text-emerald-900/90 dark:text-emerald-100/90">
                Meal log, meal plan, profile, allergy và lịch sử AI vẫn nằm ở
                MenuGreenSystem. Runtime AI chỉ đóng vai trò xử lý hỏi đáp và
                recommendation logic nặng.
              </p>
            </div>
            <div className="rounded-2xl bg-sky-50 p-4 dark:bg-sky-950/30">
              <p className="text-sm font-medium text-sky-800 dark:text-sky-300">
                Contract đã được căn chỉnh
              </p>
              <p className="mt-2 text-sm leading-6 text-sky-900/90 dark:text-sky-100/90">
                Backend hiện gửi đúng payload mà runtime cần: message, user_id,
                thread_id, request_id và conversation_history.
              </p>
            </div>
            <div className="rounded-2xl bg-zinc-100 p-4 dark:bg-zinc-900">
              <p className="text-sm font-medium text-zinc-800 dark:text-zinc-200">
                Mục tiêu tiếp theo
              </p>
              <p className="mt-2 text-sm leading-6 text-zinc-700 dark:text-zinc-300">
                Khi mobile backend cần dùng AI, nó nên gọi MenuGreenSystem API
                thay vì gọi trực tiếp runtime, để giữ được auth, meal state và
                audit log ở một nơi.
              </p>
            </div>
          </div>
        </section>
      </div>

        <section className="overflow-hidden rounded-[28px] border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="border-b border-zinc-200 px-6 py-5 dark:border-zinc-800">
          <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Các cuộc trò chuyện gần đây
          </h2>
          <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            Kiểm tra nhanh nội dung, tần suất và độ dài cuộc trò chuyện AI.
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Cuộc trò chuyện
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Xem trước
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Tin nhắn
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Hoạt động cuối
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-sm text-zinc-500">
                    Đang tải dữ liệu AI...
                  </td>
                </tr>
              ) : !overview?.recentConversations.length ? (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-sm text-zinc-500">
                    Chưa có cuộc trò chuyện nào.
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
                      {conversation.lastMessagePreview || "Không có preview"}
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
