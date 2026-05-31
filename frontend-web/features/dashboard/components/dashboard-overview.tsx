"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/layout/page-header";
import { useDashboardMetrics } from "@/features/dashboard/hooks/use-dashboard-metrics";
import { formatDateTime, formatNumber, formatVnd } from "@/lib/utils/format";

const modules = [
  {
    href: "/dashboard/users",
    title: "Người dùng",
    description: "Quản lý tài khoản, role và trạng thái hoạt động",
  },
  {
    href: "/dashboard/foods",
    title: "Món ăn",
    description: "Tìm kiếm, thêm, sửa và xóa món ăn trong hệ thống",
  },
  {
    href: "/dashboard/ingredients",
    title: "Nguyên liệu",
    description: "Quản lý danh mục nguyên liệu cho công thức",
  },
  {
    href: "/dashboard/recipes",
    title: "Công thức",
    description: "Quản lý công thức nấu ăn và thành phần",
  },
  {
    href: "/dashboard/subscription-plans",
    title: "Gói thành viên",
    description: "Quản lý gói Free, Pro và giá đăng ký",
  },
  {
    href: "/dashboard/meal-plans",
    title: "Thực đơn mẫu",
    description: "Tạo meal plan mẫu và phân phối cho user",
  },
];

function MetricCard({
  label,
  value,
  loading,
}: {
  label: string;
  value: string;
  loading: boolean;
}) {
  return (
    <div className="rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950">
      <p className="text-sm text-zinc-500 dark:text-zinc-400">{label}</p>
      <p className="mt-2 text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        {loading ? "—" : value}
      </p>
    </div>
  );
}

export function DashboardOverview() {
  const { metrics, revenue, loading, error, reload } = useDashboardMetrics();

  return (
    <div>
      <PageHeader
        title="Tổng quan"
        description="Theo dõi chỉ số hệ thống và truy cập các module quản trị"
        action={
          <Button variant="secondary" onClick={() => reload()} loading={loading}>
            Làm mới
          </Button>
        }
      />

      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <h2 className="mb-4 text-base font-semibold text-zinc-900 dark:text-zinc-50">
        Người dùng
      </h2>
      <div className="mb-8 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MetricCard
          label="Tổng người dùng"
          value={formatNumber(metrics?.totalUsers)}
          loading={loading}
        />
        <MetricCard
          label="Đang hoạt động"
          value={formatNumber(metrics?.activeUsers)}
          loading={loading}
        />
        <MetricCard
          label="Premium"
          value={formatNumber(metrics?.premiumUsers)}
          loading={loading}
        />
        <MetricCard
          label="Pro"
          value={formatNumber(metrics?.proUsers)}
          loading={loading}
        />
      </div>

      <h2 className="mb-4 text-base font-semibold text-zinc-900 dark:text-zinc-50">
        Doanh thu
      </h2>
      <div className="mb-8 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MetricCard
          label="Tổng doanh thu"
          value={formatVnd(revenue?.totalRevenueVnd)}
          loading={loading}
        />
        <MetricCard
          label="Đăng ký mới"
          value={formatVnd(revenue?.subscribeRevenueVnd)}
          loading={loading}
        />
        <MetricCard
          label="Gia hạn"
          value={formatVnd(revenue?.renewRevenueVnd)}
          loading={loading}
        />
        <MetricCard
          label="Số giao dịch"
          value={formatNumber(revenue?.transactionCount)}
          loading={loading}
        />
      </div>

      <div className="mb-8 overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="border-b border-zinc-200 px-5 py-4 dark:border-zinc-800">
          <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-50">
            Top món ăn phổ biến
          </h2>
          {metrics?.generatedAt ? (
            <p className="mt-1 text-sm text-zinc-500">
              Cập nhật lúc {formatDateTime(metrics.generatedAt)}
            </p>
          ) : null}
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead className="bg-zinc-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  #
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Món ăn
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Lượt dùng
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Calories
                </th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                  Giá ước tính
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {loading ? (
                <tr>
                  <td
                    colSpan={5}
                    className="px-4 py-8 text-center text-sm text-zinc-500"
                  >
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : !metrics?.topFoods.length ? (
                <tr>
                  <td
                    colSpan={5}
                    className="px-4 py-8 text-center text-sm text-zinc-500"
                  >
                    Chưa có dữ liệu xếp hạng.
                  </td>
                </tr>
              ) : (
                metrics.topFoods.map((food, index) => (
                  <tr
                    key={food.foodId}
                    className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40"
                  >
                    <td className="px-4 py-3 text-sm text-zinc-500">
                      {index + 1}
                    </td>
                    <td className="px-4 py-3 text-sm font-medium text-zinc-900 dark:text-zinc-50">
                      {food.foodName}
                    </td>
                    <td className="px-4 py-3 text-sm text-zinc-600 dark:text-zinc-300">
                      {formatNumber(food.useCount)}
                    </td>
                    <td className="px-4 py-3 text-sm text-zinc-600 dark:text-zinc-300">
                      {formatNumber(food.caloriesKcal)} kcal
                    </td>
                    <td className="px-4 py-3 text-sm text-zinc-600 dark:text-zinc-300">
                      {formatVnd(food.estimatedPriceVnd)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <h2 className="mb-4 text-base font-semibold text-zinc-900 dark:text-zinc-50">
        Module quản trị
      </h2>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {modules.map((module) => (
          <Link
            key={module.href}
            href={module.href}
            className="rounded-2xl border border-zinc-200 bg-white p-5 transition hover:border-emerald-300 hover:shadow-sm dark:border-zinc-800 dark:bg-zinc-950 dark:hover:border-emerald-800"
          >
            <h3 className="text-base font-semibold text-zinc-900 dark:text-zinc-50">
              {module.title}
            </h3>
            <p className="mt-2 text-sm leading-6 text-zinc-500 dark:text-zinc-400">
              {module.description}
            </p>
          </Link>
        ))}
      </div>
    </div>
  );
}
