"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { MenuGreenLogo } from "@/components/brand/menu-green-logo";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  useAuth,
  useAuthActions,
} from "@/features/auth/hooks/use-auth";

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { isAuthenticated, isAdmin, isReady } = useAuth();
  const { login } = useAuthActions();

  const [email, setEmail] = useState("admin@menugreen.app");
  const [password, setPassword] = useState("Demo@123");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (searchParams.get("error") === "not-admin") {
      setError("Tài khoản không có quyền Admin.");
    }
  }, [searchParams]);

  useEffect(() => {
    if (isReady && isAuthenticated && isAdmin) {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, isAdmin, isReady, router]);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);

    const result = await login({ email, password });
    setLoading(false);

    if (!result.success) {
      setError(result.message);
      return;
    }

    router.replace("/dashboard");
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-8 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
    >
      <div className="mb-6">
        <MenuGreenLogo size={48} className="mb-4" />
        <h1 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
          MenuGreen Admin
        </h1>
        <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
          Đăng nhập để quản lý hệ thống
        </p>
      </div>

      <div className="flex flex-col gap-4">
        <Input
          label="Email"
          name="email"
          type="email"
          autoComplete="email"
          value={email}
          onChange={(event: React.ChangeEvent<HTMLInputElement>) =>
            setEmail(event.target.value)
          }
          required
        />
        <Input
          label="Mật khẩu"
          name="password"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(event: React.ChangeEvent<HTMLInputElement>) =>
            setPassword(event.target.value)
          }
          required
        />
        {error ? (
          <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">
            {error}
          </p>
        ) : null}
        <Button type="submit" loading={loading} className="w-full">
          Đăng nhập
        </Button>
      </div>
    </form>
  );
}
