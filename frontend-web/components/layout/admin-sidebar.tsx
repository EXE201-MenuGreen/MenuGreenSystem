"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { MenuGreenLogo } from "@/components/brand/menu-green-logo";
import { cn } from "@/lib/utils/cn";

const navItems = [
  { href: "/dashboard", label: "Tổng quan", exact: true },
  { href: "/dashboard/analytics", label: "Analytics" },
  { href: "/dashboard/users", label: "Người dùng" },
  { href: "/dashboard/foods", label: "Món ăn" },
  { href: "/dashboard/ingredients", label: "Nguyên liệu" },
  { href: "/dashboard/recipes", label: "Công thức" },
  { href: "/dashboard/subscription-plans", label: "Gói thành viên" },
  { href: "/dashboard/meal-plans", label: "Thực đơn mẫu" },
  { href: "/dashboard/ai-assistant", label: "AI Assistant" },
];

export function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="flex w-64 shrink-0 flex-col border-r border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
      <div className="border-b border-zinc-200 px-5 py-5 dark:border-zinc-800">
        <Link href="/dashboard" className="flex items-center gap-2">
          <MenuGreenLogo size={36} />
          <div>
            <p className="text-sm font-semibold text-zinc-900 dark:text-zinc-50">
              MenuGreen
            </p>
            <p className="text-xs text-zinc-500">Admin Panel</p>
          </div>
        </Link>
      </div>

      <nav className="flex flex-1 flex-col gap-1 overflow-y-auto p-3">
        {navItems.map((item) => {
          const isActive = item.exact
            ? pathname === item.href
            : pathname.startsWith(item.href);

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                isActive
                  ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300"
                  : "text-zinc-600 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-900",
              )}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
