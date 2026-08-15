"use client";

import { cn } from "@/lib/utils/cn";
import type { DatePreset } from "../types/analytics-types";

interface DateRangePickerProps {
  value: DatePreset;
  onChange: (preset: DatePreset) => void;
  className?: string;
}

const presets: { value: DatePreset; label: string }[] = [
  { value: "today", label: "Hôm nay" },
  { value: "7days", label: "7 ngày" },
  { value: "30days", label: "30 ngày" },
  { value: "90days", label: "90 ngày" },
];

export function DateRangePicker({ value, onChange, className }: DateRangePickerProps) {
  return (
    <div className={cn("inline-flex rounded-lg border border-zinc-200 bg-white p-1 dark:border-zinc-800 dark:bg-zinc-950", className)}>
      {presets.map((preset) => (
        <button
          key={preset.value}
          onClick={() => onChange(preset.value)}
          className={cn(
            "rounded-md px-3 py-1.5 text-sm font-medium transition-colors",
            value === preset.value
              ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"
              : "text-zinc-600 hover:bg-zinc-100 dark:text-zinc-400 dark:hover:bg-zinc-900"
          )}
        >
          {preset.label}
        </button>
      ))}
    </div>
  );
}

// ============================================
// TAB COMPONENT
// ============================================

interface Tab {
  id: string;
  label: string;
  icon?: React.ReactNode;
}

interface TabsProps {
  tabs: Tab[];
  value: string;
  onChange: (id: string) => void;
  className?: string;
}

export function Tabs({ tabs, value, onChange, className }: TabsProps) {
  return (
    <div className={cn("flex gap-1 border-b border-zinc-200 dark:border-zinc-800", className)}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onChange(tab.id)}
          className={cn(
            "flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-medium transition-colors",
            value === tab.id
              ? "border-emerald-600 text-emerald-600 dark:border-emerald-500 dark:text-emerald-500"
              : "border-transparent text-zinc-600 hover:border-zinc-300 dark:text-zinc-400 dark:hover:border-zinc-700"
          )}
        >
          {tab.icon}
          {tab.label}
        </button>
      ))}
    </div>
  );
}

// ============================================
// BADGE COMPONENT
// ============================================

interface BadgeProps {
  children: React.ReactNode;
  variant?: "default" | "success" | "warning" | "danger" | "info";
  className?: string;
}

const badgeVariants = {
  default: "bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300",
  success: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
  warning: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  danger: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  info: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
};

export function Badge({ children, variant = "default", className }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        badgeVariants[variant],
        className
      )}
    >
      {children}
    </span>
  );
}

// ============================================
// EMPTY STATE COMPONENT
// ============================================

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center justify-center py-12 text-center", className)}>
      {icon && (
        <div className="mb-4 text-zinc-400">{icon}</div>
      )}
      <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
        {title}
      </h3>
      {description && (
        <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
          {description}
        </p>
      )}
      {action && (
        <div className="mt-4">{action}</div>
      )}
    </div>
  );
}

// ============================================
// ERROR STATE COMPONENT
// ============================================

interface ErrorStateProps {
  message: string;
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  message,
  onRetry,
  className,
}: ErrorStateProps) {
  return (
    <div className={cn("rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-900 dark:bg-red-950/30", className)}>
      <div className="flex items-center justify-between">
        <p className="text-sm text-red-700 dark:text-red-300">{message}</p>
        {onRetry && (
          <button
            onClick={onRetry}
            className="text-sm font-medium text-red-600 hover:text-red-800 dark:text-red-400"
          >
            Thử lại
          </button>
        )}
      </div>
    </div>
  );
}
