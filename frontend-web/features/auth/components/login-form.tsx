"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { AlertCircle } from "lucide-react";

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

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
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
          <div className="rounded-lg border border-red-200 bg-red-50 p-3 dark:border-red-800 dark:bg-red-950/30">
            <div className="flex items-start gap-2">
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-red-600 dark:text-red-400" />
              <div className="flex-1">
                <p className="text-sm font-medium text-red-800 dark:text-red-200">
                  Đăng nhập thất bại
                </p>
                <p className="mt-0.5 text-sm text-red-700 dark:text-red-300">
                  {error}
                </p>
              </div>
            </div>
          </div>
        ) : null}
        <Button type="submit" loading={loading} className="w-full">
          Đăng nhập
        </Button>
      </div>
    </form>
  );
}
