"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import type { UserAdmin } from "@/features/users/types";

const ROLE_OPTIONS = ["User", "Coach", "Admin"];

interface AssignRoleDialogProps {
  user: UserAdmin | null;
  loading?: boolean;
  onClose: () => void;
  onConfirm: (user: UserAdmin, role: string) => void;
}

export function AssignRoleDialog({
  user,
  loading = false,
  onClose,
  onConfirm,
}: AssignRoleDialogProps) {
  const [role, setRole] = useState(user?.role ?? "User");

  if (!user) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div
        className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950"
        role="dialog"
        aria-modal="true"
        aria-labelledby="assign-role-title"
      >
        <h2
          id="assign-role-title"
          className="text-lg font-semibold text-zinc-900 dark:text-zinc-50"
        >
          Gán role
        </h2>
        <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
          {user.fullName || "Chưa có tên"} — {user.email}
        </p>

        <div className="mt-4">
          <Select
            label="Role mới"
            value={role}
            onChange={(event) => setRole(event.target.value)}
          >
            {ROLE_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </Select>
        </div>

        <div className="mt-6 flex justify-end gap-3">
          <Button variant="secondary" onClick={onClose} disabled={loading}>
            Hủy
          </Button>
          <Button
            loading={loading}
            onClick={() => onConfirm(user, role)}
            disabled={role === user.role}
          >
            Xác nhận
          </Button>
        </div>
      </div>
    </div>
  );
}
