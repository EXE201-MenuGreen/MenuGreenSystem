"use client";

import { useEffect, useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { adminUserApi } from "@/features/users/api/admin-user-api";
import { subscriptionPlanApi } from "@/features/subscription-plans/api/subscription-plan-api";
import type { SubscriptionPlan } from "@/features/subscription-plans/types";
import type { AdminUserMembership, UserAdmin } from "@/features/users/types";
import { getErrorMessage } from "@/lib/api/errors";
import { formatDateTime } from "@/lib/utils/format";

interface ManageMembershipDialogProps {
  user: UserAdmin | null;
  onClose: () => void;
  onChanged: () => Promise<void>;
}

export function ManageMembershipDialog({ user, onClose, onChanged }: ManageMembershipDialogProps) {
  const [membership, setMembership] = useState<AdminUserMembership | null>(null);
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [planId, setPlanId] = useState("");
  const [durationDays, setDurationDays] = useState(30);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const grantablePlans = useMemo(
    () => plans.filter((plan) => {
      const group = plan.featureGroup?.trim().toLowerCase();
      return plan.isActive && group !== "free" && group !== "basic";
    }),
    [plans],
  );

  useEffect(() => {
    if (!user) return;
    let active = true;
    Promise.all([
      adminUserApi.getMemberships(user.id),
      subscriptionPlanApi.getAll({ isActive: true }),
    ])
      .then(([membershipData, planData]) => {
        if (!active) return;
        setMembership(membershipData);
        setPlans(planData);
        const first = planData.find((plan) => {
          const group = plan.featureGroup?.trim().toLowerCase();
          return plan.isActive && group !== "free" && group !== "basic";
        });
        setPlanId(first?.id ?? "");
        setDurationDays(first?.durationDays || 30);
      })
      .catch((err) => active && setError(getErrorMessage(err, "Không thể tải thông tin gói")))
      .finally(() => active && setBusy(false));
    return () => { active = false; };
  }, [user]);

  if (!user) return null;

  async function grant() {
    if (!planId || durationDays < 1) return;
    setBusy(true);
    setError(null);
    try {
      const result = await adminUserApi.grantMembership(user!.id, {
        subscriptionPlanId: planId,
        durationDays,
        note: note.trim() || undefined,
      });
      setMembership(result);
      setNote("");
      await onChanged();
    } catch (err) {
      setError(getErrorMessage(err, "Không thể cấp gói"));
    } finally {
      setBusy(false);
    }
  }

  async function extend(subscriptionId: string) {
    setBusy(true);
    setError(null);
    try {
      const result = await adminUserApi.extendMembership(
        user!.id,
        subscriptionId,
        durationDays,
        note.trim() || undefined,
      );
      setMembership(result);
      setNote("");
      await onChanged();
    } catch (err) {
      setError(getErrorMessage(err, "Không thể gia hạn gói"));
    } finally {
      setBusy(false);
    }
  }

  async function revoke(subscriptionId: string, planName: string) {
    const reason = window.prompt(`Lý do thu hồi gói ${planName}:`);
    if (!reason?.trim()) return;
    setBusy(true);
    setError(null);
    try {
      const result = await adminUserApi.revokeMembership(user!.id, subscriptionId, reason.trim());
      setMembership(result);
      await onChanged();
    } catch (err) {
      setError(getErrorMessage(err, "Không thể thu hồi gói"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl border border-zinc-200 bg-white p-6 shadow-xl dark:border-zinc-800 dark:bg-zinc-950">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">Quản lý gói thành viên</h2>
            <p className="mt-1 text-sm text-zinc-500">{user.fullName || "Chưa có tên"} — {user.email}</p>
          </div>
          <Button variant="secondary" onClick={onClose} disabled={busy}>Đóng</Button>
        </div>

        {error ? <div className="mt-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

        <div className="mt-5 grid gap-3 rounded-xl border border-zinc-200 p-4 sm:grid-cols-3 dark:border-zinc-800">
          <div><div className="text-xs text-zinc-500">Quyền hiện tại</div><div className="mt-1 font-semibold uppercase">{membership && membership.tier !== "free" ? membership.tier : "Cơ bản"}</div></div>
          <div><div className="text-xs text-zinc-500">Hết hạn gần nhất</div><div className="mt-1 text-sm">{membership?.expiresAt ? formatDateTime(membership.expiresAt) : "Không có"}</div></div>
          <div><div className="text-xs text-zinc-500">Entitlements</div><div className="mt-1 text-xs text-zinc-600">{membership?.entitlements.join(", ") || "free_features"}</div></div>
        </div>

        <div className="mt-5 rounded-xl border border-zinc-200 p-4 dark:border-zinc-800">
          <h3 className="font-semibold">Cấp gói mới</h3>
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <Select label="Gói" value={planId} onChange={(event) => {
              const selected = grantablePlans.find((plan) => plan.id === event.target.value);
              setPlanId(event.target.value);
              setDurationDays(selected?.durationDays || 30);
            }}>
              {grantablePlans.map((plan) => <option key={plan.id} value={plan.id}>{plan.name}</option>)}
            </Select>
            <Input label="Số ngày" type="number" min={1} max={3650} value={durationDays} onChange={(event) => setDurationDays(Number(event.target.value))} />
          </div>
          <Textarea className="mt-3" label="Ghi chú" value={note} onChange={(event) => setNote(event.target.value)} placeholder="Lý do cấp hoặc gia hạn" />
          <div className="mt-3 flex justify-end"><Button onClick={grant} loading={busy} disabled={!planId || durationDays < 1}>Cấp gói</Button></div>
        </div>

        <div className="mt-5">
          <h3 className="font-semibold">Lịch sử gói</h3>
          <div className="mt-3 space-y-3">
            {membership?.memberships.length ? membership.memberships.map((item) => (
              <div key={item.subscriptionId} className="flex flex-col gap-3 rounded-xl border border-zinc-200 p-4 sm:flex-row sm:items-center sm:justify-between dark:border-zinc-800">
                <div>
                  <div className="flex items-center gap-2"><span className="font-medium">{item.planName}</span><Badge variant={item.status === "Active" ? "success" : item.status === "PendingPayment" ? "warning" : "neutral"}>{item.status}</Badge></div>
                  <div className="mt-1 text-xs text-zinc-500">{formatDateTime(item.startDate)} → {formatDateTime(item.endDate)} · còn {item.daysRemaining} ngày</div>
                </div>
                <div className="flex gap-2">
                  <Button variant="secondary" disabled={busy || item.status === "Cancelled" || item.status === "PendingPayment"} onClick={() => extend(item.subscriptionId)}>Gia hạn</Button>
                  <Button variant="danger" disabled={busy || item.status === "Cancelled"} onClick={() => revoke(item.subscriptionId, item.planName)}>Thu hồi</Button>
                </div>
              </div>
            )) : <div className="rounded-xl border border-dashed border-zinc-300 p-6 text-center text-sm text-zinc-500">Tài khoản chưa có subscription.</div>}
          </div>
        </div>
      </div>
    </div>
  );
}
