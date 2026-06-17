"use client";

import { Button } from "@/components/ui/button";
import { useAuth } from "@/features/auth/hooks/use-auth";

export function AdminHeader() {
  const { fullName, logout, loggingOut } = useAuth();

  return (
    <header className="flex h-16 items-center justify-between border-b border-zinc-200 bg-white px-6 dark:border-zinc-800 dark:bg-zinc-950">
      <div>
        <p className="text-sm text-zinc-500 dark:text-zinc-400">Xin chao</p>
        <p className="text-sm font-medium text-zinc-900 dark:text-zinc-50">
          {fullName || "Admin"}
        </p>
      </div>
      <Button variant="secondary" loading={loggingOut} onClick={() => logout()}>
        Dang xuat
      </Button>
    </header>
  );
}
