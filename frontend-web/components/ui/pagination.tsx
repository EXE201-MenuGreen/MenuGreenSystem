"use client";

import {
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
} from "lucide-react";
import { cn } from "@/lib/utils/cn";

export interface PaginationProps {
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  pageSizeOptions?: number[];
  itemName?: string;
  disabled?: boolean;
  className?: string;
}

export function Pagination({
  page,
  pageSize,
  totalCount,
  totalPages,
  onPageChange,
  onPageSizeChange,
  pageSizeOptions = [10, 20, 50, 100],
  itemName = "mục",
  disabled = false,
  className,
}: PaginationProps) {
  if (totalCount <= 0) return null;

  const validTotalPages = Math.max(1, totalPages || Math.ceil(totalCount / pageSize));
  const currentPage = Math.min(Math.max(1, page), validTotalPages);
  const startItem = Math.min((currentPage - 1) * pageSize + 1, totalCount);
  const endItem = Math.min(currentPage * pageSize, totalCount);

  // Generate page numbers with smart ellipsis
  function getPageNumbers(): (number | string)[] {
    if (validTotalPages <= 7) {
      return Array.from({ length: validTotalPages }, (_, i) => i + 1);
    }

    if (currentPage <= 4) {
      return [1, 2, 3, 4, 5, "...", validTotalPages];
    }

    if (currentPage >= validTotalPages - 3) {
      return [
        1,
        "...",
        validTotalPages - 4,
        validTotalPages - 3,
        validTotalPages - 2,
        validTotalPages - 1,
        validTotalPages,
      ];
    }

    return [
      1,
      "...",
      currentPage - 1,
      currentPage,
      currentPage + 1,
      "...",
      validTotalPages,
    ];
  }

  const pages = getPageNumbers();

  return (
    <div
      className={cn(
        "flex flex-col items-center justify-between gap-4 border-t border-zinc-200 px-4 py-3 sm:flex-row dark:border-zinc-800",
        className,
      )}
    >
      {/* Left side: Information and Page Size Selector */}
      <div className="flex flex-wrap items-center gap-3 text-sm text-zinc-600 dark:text-zinc-400">
        <span>
          Hiển thị{" "}
          <span className="font-semibold text-zinc-900 dark:text-zinc-100">
            {startItem}
          </span>
          –
          <span className="font-semibold text-zinc-900 dark:text-zinc-100">
            {endItem}
          </span>{" "}
          trên tổng số{" "}
          <span className="font-semibold text-zinc-900 dark:text-zinc-100">
            {totalCount}
          </span>{" "}
          {itemName}
        </span>

        {onPageSizeChange && (
          <div className="flex items-center gap-1.5 pl-2 border-l border-zinc-200 dark:border-zinc-800">
            <span className="text-xs">Số lượng:</span>
            <select
              value={pageSize}
              disabled={disabled}
              onChange={(e) => onPageSizeChange(Number(e.target.value))}
              aria-label="Số lượng mỗi trang"
              className="h-8 rounded-lg border border-zinc-300 bg-white px-2 text-xs font-medium text-zinc-900 shadow-sm transition hover:border-zinc-400 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500 disabled:opacity-50 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100 dark:hover:border-zinc-600"
            >
              {pageSizeOptions.map((option) => (
                <option key={option} value={option}>
                  {option} / trang
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Right side: Navigation Controls */}
      <nav
        role="navigation"
        aria-label="Pagination"
        className="flex items-center gap-1"
      >
        {/* First page */}
        <button
          type="button"
          onClick={() => onPageChange(1)}
          disabled={disabled || currentPage <= 1}
          aria-label="Trang đầu"
          title="Trang đầu"
          className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-200 bg-white text-zinc-600 transition hover:bg-zinc-50 hover:text-zinc-900 disabled:pointer-events-none disabled:opacity-40 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-100"
        >
          <ChevronsLeft className="h-4 w-4" />
        </button>

        {/* Previous page */}
        <button
          type="button"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={disabled || currentPage <= 1}
          aria-label="Trang trước"
          title="Trang trước"
          className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-200 bg-white text-zinc-600 transition hover:bg-zinc-50 hover:text-zinc-900 disabled:pointer-events-none disabled:opacity-40 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-100"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>

        {/* Page pills */}
        <div className="flex items-center gap-1">
          {pages.map((p, idx) => {
            if (typeof p === "string") {
              return (
                <span
                  key={`ellipsis-${idx}`}
                  className="flex h-8 w-8 items-center justify-center text-xs text-zinc-400 dark:text-zinc-600"
                >
                  •••
                </span>
              );
            }

            const isActive = p === currentPage;

            return (
              <button
                key={`page-${p}`}
                type="button"
                onClick={() => onPageChange(p)}
                disabled={disabled}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "inline-flex h-8 min-w-[2rem] items-center justify-center rounded-lg px-2 text-xs font-medium transition",
                  isActive
                    ? "bg-emerald-600 text-white shadow-sm font-semibold hover:bg-emerald-700"
                    : "border border-zinc-200 bg-white text-zinc-700 hover:bg-zinc-50 hover:text-zinc-900 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-zinc-100",
                  disabled && "pointer-events-none opacity-50",
                )}
              >
                {p}
              </button>
            );
          })}
        </div>

        {/* Next page */}
        <button
          type="button"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={disabled || currentPage >= validTotalPages}
          aria-label="Trang sau"
          title="Trang sau"
          className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-200 bg-white text-zinc-600 transition hover:bg-zinc-50 hover:text-zinc-900 disabled:pointer-events-none disabled:opacity-40 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-100"
        >
          <ChevronRight className="h-4 w-4" />
        </button>

        {/* Last page */}
        <button
          type="button"
          onClick={() => onPageChange(validTotalPages)}
          disabled={disabled || currentPage >= validTotalPages}
          aria-label="Trang cuối"
          title="Trang cuối"
          className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-200 bg-white text-zinc-600 transition hover:bg-zinc-50 hover:text-zinc-900 disabled:pointer-events-none disabled:opacity-40 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-100"
        >
          <ChevronsRight className="h-4 w-4" />
        </button>
      </nav>
    </div>
  );
}
