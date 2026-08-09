"use client";

import { useState } from "react";
import { DollarSign, TrendingUp, TrendingDown, CreditCard, RefreshCw } from "lucide-react";
import { KpiCard, DonutChart, Legend } from "../components/analytics-cards";
import { DateRangePicker } from "../components/analytics-ui";
import { useRevenueTimeSeries, useRevenueByPlan } from "../hooks/use-analytics";
import { formatVnd } from "@/lib/utils/format";
import { cn } from "@/lib/utils/cn";
import type { DatePreset, DateRange } from "../types/analytics-types";

// ============================================
// LINE CHART COMPONENT (Simple SVG)
// ============================================

interface LineChartProps {
  data: Array<{ date: string; value: number; label?: string }>;
  height?: number;
  color?: string;
  label?: string;
}

function RevenueLineChart({ data, height = 200, color = "#10b981" }: LineChartProps) {
  if (!data.length) return null;

  const maxValue = Math.max(...data.map((d) => d.value));
  const minValue = Math.min(...data.map((d) => d.value));
  const range = maxValue - minValue || 1;

  const padding = { top: 20, right: 20, bottom: 40, left: 70 };
  const width = 600;
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  const points = data.map((d, i) => ({
    x: padding.left + (i / (data.length - 1 || 1)) * chartWidth,
    y: padding.top + (1 - (d.value - minValue) / range) * chartHeight,
    date: d.date,
    value: d.value,
  }));

  const pathD = points
    .map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`)
    .join(" ");

  const areaD = `${pathD} L ${points[points.length - 1]?.x} ${padding.top + chartHeight} L ${padding.left} ${padding.top + chartHeight} Z`;

  const formatValue = (v: number) => {
    if (v >= 1000000) return `${(v / 1000000).toFixed(1)}M`;
    if (v >= 1000) return `${(v / 1000).toFixed(0)}K`;
    return v.toString();
  };

  return (
    <div className="w-full overflow-x-auto">
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full min-w-[400px]"
        style={{ height: height }}
      >
        {/* Grid lines */}
        {[0, 0.25, 0.5, 0.75, 1].map((ratio) => {
          const y = padding.top + ratio * chartHeight;
          const value = maxValue - ratio * range;
          return (
            <g key={ratio}>
              <line
                x1={padding.left}
                y1={y}
                x2={width - padding.right}
                y2={y}
                stroke="currentColor"
                strokeWidth={1}
                className="text-zinc-200 dark:text-zinc-800"
              />
              <text
                x={padding.left - 8}
                y={y + 4}
                textAnchor="end"
                className="fill-zinc-500 text-xs dark:fill-zinc-400"
              >
                {formatValue(value)}
              </text>
            </g>
          );
        })}

        {/* Area fill */}
        <path
          d={areaD}
          fill={color}
          fillOpacity={0.1}
          className="transition-all duration-500"
        />

        {/* Line */}
        <path
          d={pathD}
          fill="none"
          stroke={color}
          strokeWidth={2}
          strokeLinecap="round"
          strokeLinejoin="round"
          className="transition-all duration-500"
        />

        {/* Data points */}
        {points.map((p, i) => (
          <circle
            key={i}
            cx={p.x}
            cy={p.y}
            r={3}
            fill={color}
            className="transition-all duration-200 hover:r-4"
          />
        ))}

        {/* X-axis labels */}
        {points
          .filter((_, i) => i % Math.ceil(points.length / 6) === 0 || i === points.length - 1)
          .map((p, i) => (
            <text
              key={i}
              x={p.x}
              y={height - 10}
              textAnchor="middle"
              className="fill-zinc-500 text-xs dark:fill-zinc-400"
            >
              {p.date.slice(5)}
            </text>
          ))}
      </svg>
    </div>
  );
}

// ============================================
// REVENUE STATISTICS DASHBOARD
// ============================================

export function RevenueStatisticsDashboard() {
  const [datePreset, setDatePreset] = useState<DatePreset>("30days");
  const [dateRange, setDateRange] = useState<DateRange>(() => {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    return {
      from: new Date(today.getTime() - 30 * 86400000),
      to: new Date(today.getTime() + 86400000 - 1),
    };
  });

  const {
    data: timeSeriesData,
    isLoading: timeSeriesLoading,
    error: timeSeriesError,
    refetch: refetchTimeSeries,
  } = useRevenueTimeSeries(datePreset);

  const {
    data: byPlanData,
    isLoading: byPlanLoading,
    error: byPlanError,
    refetch: refetchByPlan,
  } = useRevenueByPlan(datePreset);

  const loading = timeSeriesLoading || byPlanLoading;
  const error = timeSeriesError || byPlanError;

  // Calculate stats from time series
  const stats = timeSeriesData?.length
    ? {
        totalRevenue: timeSeriesData.reduce((sum, d) => sum + d.totalRevenue, 0),
        subscribeRevenue: timeSeriesData.reduce((sum, d) => sum + d.subscribeRevenue, 0),
        renewRevenue: timeSeriesData.reduce((sum, d) => sum + d.renewRevenue, 0),
        transactionCount: timeSeriesData.reduce((sum, d) => sum + d.transactionCount, 0),
      }
    : null;

  // Prepare chart data
  const chartData = timeSeriesData?.map((d) => ({
    date: d.date,
    value: d.totalRevenue,
  })) ?? [];

  // Plan colors
  const PLAN_COLORS: Record<string, string> = {
    basic: "#10b981",
    casual: "#3b82f6",
    office: "#f59e0b",
    gym: "#8b5cf6",
  };

  const planSegments = byPlanData?.map((p) => ({
    name: p.planName,
    value: p.revenue,
    color: PLAN_COLORS[p.planKey] ?? "#6b7280",
  })) ?? [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
            Thống kê doanh thu
          </h1>
          <p className="mt-1 text-sm text-zinc-500">
            Theo dõi doanh thu từ đăng ký và gia hạn gói thành viên
          </p>
        </div>
        <div className="flex items-center gap-2">
          <DateRangePicker value={datePreset} onChange={setDatePreset} />
          <button
            onClick={() => {
              refetchTimeSeries();
              refetchByPlan();
            }}
            className="flex h-9 w-9 items-center justify-center rounded-lg border border-zinc-200 bg-white text-zinc-500 hover:bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-400 dark:hover:bg-zinc-900"
          >
            <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
          </button>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-900 dark:bg-red-950/30">
          <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <KpiCard
          label="Tổng doanh thu"
          value={loading ? "—" : formatVnd(stats?.totalRevenue)}
          icon={<DollarSign className="h-5 w-5" />}
          loading={loading}
        />
        <KpiCard
          label="Đăng ký mới"
          value={loading ? "—" : formatVnd(stats?.subscribeRevenue)}
          icon={<TrendingUp className="h-5 w-5" />}
          loading={loading}
        />
        <KpiCard
          label="Gia hạn"
          value={loading ? "—" : formatVnd(stats?.renewRevenue)}
          icon={<TrendingDown className="h-5 w-5" />}
          loading={loading}
        />
        <KpiCard
          label="Số giao dịch"
          value={loading ? "—" : (stats?.transactionCount ?? 0).toLocaleString()}
          icon={<CreditCard className="h-5 w-5" />}
          loading={loading}
        />
      </div>

      {/* Charts Row */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Revenue Trend */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950 lg:col-span-2">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Xu hướng doanh thu
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            Doanh thu theo thời gian
          </p>

          <div className="mt-6">
            {loading ? (
              <div className="flex h-52 items-center justify-center">
                <p className="text-sm text-zinc-500">Đang tải...</p>
              </div>
            ) : chartData.length > 0 ? (
              <RevenueLineChart data={chartData} height={200} />
            ) : (
              <div className="flex h-52 items-center justify-center">
                <p className="text-sm text-zinc-500">Chưa có dữ liệu</p>
              </div>
            )}
          </div>
        </div>

        {/* Revenue by Plan */}
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Doanh thu theo gói
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            Phân bổ doanh thu theo gói thành viên
          </p>

          <div className="mt-6">
            {loading ? (
              <div className="flex h-40 items-center justify-center">
                <p className="text-sm text-zinc-500">Đang tải...</p>
              </div>
            ) : planSegments.length > 0 ? (
              <>
                <div className="flex items-center justify-center">
                  <DonutChart
                    segments={planSegments}
                    size={160}
                    strokeWidth={24}
                  />
                </div>
                <div className="mt-4">
                  <Legend
                    className="flex-col"
                    items={planSegments.map((s) => ({
                      name: s.name,
                      value: `${((s.value / (stats?.totalRevenue || 1)) * 100).toFixed(1)}%`,
                      color: s.color,
                    }))}
                  />
                </div>
              </>
            ) : (
              <div className="flex h-40 items-center justify-center">
                <p className="text-sm text-zinc-500">Chưa có dữ liệu</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Revenue Table */}
      {byPlanData && byPlanData.length > 0 && (
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
            Chi tiết theo gói
          </h3>
          <p className="mt-1 text-sm text-zinc-500">
            Thông tin chi tiết về doanh thu từng gói thành viên
          </p>

          <div className="mt-6 overflow-x-auto">
            <table className="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
              <thead className="bg-zinc-50 dark:bg-zinc-900/50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
                    Gói
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">
                    Doanh thu
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">
                    Người đăng ký
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-zinc-500">
                    Tỷ lệ
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
                {byPlanData.map((plan) => (
                  <tr key={plan.planKey} className="hover:bg-zinc-50/80 dark:hover:bg-zinc-900/40">
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-3">
                        <span
                          className="h-3 w-3 rounded-full"
                          style={{ backgroundColor: PLAN_COLORS[plan.planKey] ?? "#6b7280" }}
                        />
                        <span className="font-medium text-zinc-900 dark:text-zinc-50">
                          {plan.planName}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-right text-sm text-zinc-600 dark:text-zinc-300">
                      {formatVnd(plan.revenue)}
                    </td>
                    <td className="px-4 py-4 text-right text-sm text-zinc-600 dark:text-zinc-300">
                      {plan.subscribers.toLocaleString()}
                    </td>
                    <td className="px-4 py-4 text-right text-sm text-zinc-600 dark:text-zinc-300">
                      {plan.percent.toFixed(1)}%
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
