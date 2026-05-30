import { Suspense } from "react";
import { LoginForm } from "@/features/auth/components/login-form";

function LoginFallback() {
  return (
    <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-8 dark:border-zinc-800 dark:bg-zinc-950">
      <p className="text-sm text-zinc-500">Đang tải...</p>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<LoginFallback />}>
      <LoginForm />
    </Suspense>
  );
}
