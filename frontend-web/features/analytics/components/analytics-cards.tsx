"use client";

import { cn } from "@/lib/utils/cn";

// ============================================
// KPI CARD COMPONENT
// ============================================

interface KpiCardProps {
  label: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  icon?: React.ReactNode;
  loading?: boolean;
  className?: string;
}

export function KpiCard({
  label,
  value,
  change,
  changeLabel,
  icon,
  loading = false,
  className,
}: KpiCardProps) {
  const isPositive = change !== undefined && change > 0;
  const isNegative = change !== undefined && change < 0;

  return (
    <div
      className={cn(
        "rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950",
        className
      )}
    >
      <div className="flex items-start justify-between">
        <p className="text-sm font-medium uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
          {label}
        </p>
        {icon && (
          <div className="text-zinc-400">{icon}</div>
        )}
      </div>

      <p className="mt-2 text-3xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50">
        {loading ? "—" : value}
      </p>

      {change !== undefined && (
        <div className="mt-2 flex items-center gap-1">
          <span
            className={cn(
              "inline-flex items-center gap-1 text-sm font-medium",
              isPositive && "text-green-600 dark:text-green-400",
              isNegative && "text-red-600 dark:text-red-400",
              !isPositive && !isNegative && "text-zinc-500"
            )}
          >
            {isPositive && "↑"}
            {isNegative && "↓"}
            {Math.abs(change).toFixed(1)}%
          </span>
          {changeLabel && (
            <span className="text-sm text-zinc-500">{changeLabel}</span>
          )}
        </div>
      )}
    </div>
  );
}

// ============================================
// PROGRESS BAR COMPONENT
// ============================================

interface ProgressBarProps {
  label: string;
  value: number;
  max: number;
  color?: "emerald" | "purple" | "orange" | "yellow" | "red";
  showPercent?: boolean;
  className?: string;
}

const colorClasses = {
  emerald: "bg-emerald-500",
  purple: "bg-purple-500",
  orange: "bg-orange-500",
  yellow: "bg-yellow-500",
  red: "bg-red-500",
};

export function ProgressBar({
  label,
  value,
  max,
  color = "emerald",
  showPercent = true,
  className,
}: ProgressBarProps) {
  const percent = max > 0 ? Math.min((value / max) * 100, 100) : 0;

  return (
    <div className={cn("space-y-2", className)}>
      <div className="flex justify-between text-sm">
        <span className="font-medium text-zinc-700 dark:text-zinc-300">
          {label}
        </span>
        {showPercent && (
          <span className="text-zinc-500">{percent.toFixed(1)}%</span>
        )}
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
        <div
          className={cn(
            "h-full rounded-full transition-all duration-500",
            colorClasses[color]
          )}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}

// ============================================
// DONUT CHART COMPONENT (Simple CSS)
// ============================================

interface DonutSegment {
  name: string;
  value: number;
  color: string;
}

interface DonutChartProps {
  segments: DonutSegment[];
  size?: number;
  strokeWidth?: number;
  className?: string;
}

export function DonutChart({
  segments,
  size = 200,
  strokeWidth = 30,
  className,
}: DonutChartProps) {
  const total = segments.reduce((sum, s) => sum + s.value, 0);
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const center = size / 2;

  let cumulativePercent = 0;

  return (
    <div className={cn("relative inline-flex items-center justify-center", className)}>
      <svg width={size} height={size} className="-rotate-90">
        {/* Background circle */}
        <circle
          cx={center}
          cy={center}
          r={radius}
          fill="none"
          stroke="currentColor"
          strokeWidth={strokeWidth}
          className="text-zinc-200 dark:text-zinc-800"
        />
        {/* Segments */}
        {segments.map((segment, index) => {
          const percent = total > 0 ? segment.value / total : 0;
          const dashLength = circumference * percent;
          const dashOffset = circumference * cumulativePercent;
          cumulativePercent += percent;

          return (
            <circle
              key={index}
              cx={center}
              cy={center}
              r={radius}
              fill="none"
              stroke={segment.color}
              strokeWidth={strokeWidth}
              strokeDasharray={`${dashLength} ${circumference - dashLength}`}
              strokeDashoffset={-dashOffset}
              className="transition-all duration-500"
            />
          );
        })}
      </svg>
      {/* Center text */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
          {total.toLocaleString()}
        </span>
        <span className="text-sm text-zinc-500">Tổng</span>
      </div>
    </div>
  );
}

// ============================================
// LEGEND COMPONENT
// ============================================

interface LegendItem {
  name: string;
  value: number | string;
  color: string;
  percent?: number;
}

interface LegendProps {
  items: LegendItem[];
  className?: string;
}

export function Legend({ items, className }: LegendProps) {
  return (
    <div className={cn("space-y-2", className)}>
      {items.map((item, index) => (
        <div key={index} className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div
              className="h-3 w-3 rounded-full"
              style={{ backgroundColor: item.color }}
            />
            <span className="text-sm text-zinc-600 dark:text-zinc-400">
              {item.name}
            </span>
          </div>
          <div className="flex items-center gap-2">
            {item.percent !== undefined && (
              <span className="text-sm text-zinc-500">
                {item.percent.toFixed(1)}%
              </span>
            )}
            <span className="text-sm font-medium text-zinc-900 dark:text-zinc-50">
              {typeof item.value === "number"
                ? item.value.toLocaleString()
                : item.value}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}

// ============================================
// STAT CARD COMPONENT
// ============================================

interface StatCardProps {
  title: string;
  stats: Array<{
    label: string;
    value: string | number;
    color?: string;
  }>;
  className?: string;
}

export function StatCard({ title, stats, className }: StatCardProps) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950",
        className
      )}
    >
      <h3 className="text-sm font-medium uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
        {title}
      </h3>
      <div className="mt-4 space-y-3">
        {stats.map((stat, index) => (
          <div key={index} className="flex items-center justify-between">
            <span className="text-sm text-zinc-600 dark:text-zinc-400">
              {stat.label}
            </span>
            <span
              className="text-sm font-semibold"
              style={{
                color: stat.color || "inherit",
              }}
            >
              {stat.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ============================================
// LOADING SKELETON
// ============================================

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div
      className={cn(
        "animate-pulse rounded-lg bg-zinc-200 dark:bg-zinc-800",
        className
      )}
    />
  );
}

export function KpiCardSkeleton() {
  return (
    <div className="rounded-2xl border border-zinc-200 bg-white p-5 dark:border-zinc-800 dark:bg-zinc-950">
      <Skeleton className="h-4 w-24" />
      <Skeleton className="mt-3 h-8 w-16" />
      <Skeleton className="mt-2 h-4 w-20" />
    </div>
  );
}
