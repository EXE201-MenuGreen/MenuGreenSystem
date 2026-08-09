"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import {
  Award,
  CalendarDays,
  CheckCircle2,
  Clock3,
  FileBadge2,
  ImageIcon,
  MapPin,
  RefreshCw,
  Search,
  ShieldCheck,
  UserRoundCheck,
  XCircle,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/layout/page-header";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils/cn";
import { formatDateTime } from "@/lib/utils/format";
import { useCoachApplications } from "@/features/coach-applications/hooks/use-coach-applications";
import type {
  CoachApplication,
  CoachApplicationStatus,
  CoachReviewDecision,
  CoachReviewRequest,
} from "@/features/coach-applications/types";

const statusOptions: Array<{
  value?: CoachApplicationStatus;
  label: string;
}> = [
  { label: "Tất cả" },
  { value: "PendingReview", label: "Chờ duyệt" },
  { value: "NeedsRevision", label: "Cần bổ sung" },
  { value: "Approved", label: "Đã duyệt" },
  { value: "Rejected", label: "Từ chối" },
];

export function CoachApplicationManagement() {
  const {
    applications,
    filtered,
    selected,
    selectedId,
    status,
    query,
    loading,
    actionLoading,
    error,
    notice,
    setSelectedId,
    setStatus,
    setQuery,
    reload,
    review,
  } = useCoachApplications();
  const [dialogDecision, setDialogDecision] =
    useState<CoachReviewDecision | null>(null);

  const counts = useMemo(
    () => ({
      pending: applications.filter(
        (item) => item.applicationStatus === "PendingReview",
      ).length,
      revision: applications.filter(
        (item) => item.applicationStatus === "NeedsRevision",
      ).length,
      approved: applications.filter(
        (item) => item.applicationStatus === "Approved",
      ).length,
      rejected: applications.filter(
        (item) => item.applicationStatus === "Rejected",
      ).length,
    }),
    [applications],
  );

  async function handleReview(request: CoachReviewRequest) {
    if (!selected) return;
    await review(selected, request);
    setDialogDecision(null);
  }

  return (
    <div>
      <PageHeader
        title="Duyệt hồ sơ PT"
        description="Kiểm tra danh tính, chuyên môn, chứng chỉ và hình ảnh trước khi kích hoạt PT"
        action={
          <Button
            variant="secondary"
            onClick={() => reload()}
            loading={loading}
          >
            <RefreshCw className="mr-2 size-4" aria-hidden="true" />
            Làm mới
          </Button>
        }
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <SummaryCard
          label="Chờ duyệt"
          value={counts.pending}
          icon={Clock3}
          tone="amber"
        />
        <SummaryCard
          label="Cần bổ sung"
          value={counts.revision}
          icon={FileBadge2}
          tone="sky"
        />
        <SummaryCard
          label="Đã xác minh"
          value={counts.approved}
          icon={UserRoundCheck}
          tone="emerald"
        />
        <SummaryCard
          label="Đã từ chối"
          value={counts.rejected}
          icon={XCircle}
          tone="red"
        />
      </div>

      {notice ? (
        <div className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-300">
          {notice}
        </div>
      ) : null}
      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex flex-wrap gap-2" aria-label="Lọc trạng thái hồ sơ">
          {statusOptions.map((option) => (
            <button
              key={option.label}
              type="button"
              onClick={() => setStatus(option.value)}
              className={cn(
                "min-h-10 rounded-lg border px-3 text-sm font-medium transition-colors",
                status === option.value
                  ? "border-emerald-600 bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300"
                  : "border-zinc-200 bg-white text-zinc-600 hover:bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-300",
              )}
            >
              {option.label}
            </button>
          ))}
        </div>
        <div className="relative w-full lg:w-80">
          <Search
            className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-zinc-400"
            aria-hidden="true"
          />
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Tìm tên, email, khu vực..."
            aria-label="Tìm hồ sơ PT"
            className="pl-9"
          />
        </div>
      </div>

      <div className="grid min-h-[640px] overflow-hidden rounded-2xl border border-zinc-200 bg-white xl:grid-cols-[360px_minmax(0,1fr)] dark:border-zinc-800 dark:bg-zinc-950">
        <aside className="border-b border-zinc-200 xl:border-b-0 xl:border-r dark:border-zinc-800">
          <div className="border-b border-zinc-200 px-4 py-3 text-sm text-zinc-500 dark:border-zinc-800">
            <span className="tabular-nums">{filtered.length}</span> hồ sơ
          </div>
          <div className="max-h-[720px] overflow-y-auto p-2">
            {loading ? (
              <ApplicationListSkeleton />
            ) : filtered.length === 0 ? (
              <div className="px-5 py-16 text-center">
                <FileBadge2
                  className="mx-auto mb-3 size-10 text-zinc-300"
                  aria-hidden="true"
                />
                <p className="font-medium text-zinc-800 dark:text-zinc-100">
                  Chưa có hồ sơ phù hợp
                </p>
                <p className="mt-1 text-pretty text-sm text-zinc-500">
                  Thử đổi trạng thái lọc hoặc từ khóa tìm kiếm.
                </p>
              </div>
            ) : (
              filtered.map((application) => (
                <ApplicationListItem
                  key={application.id}
                  application={application}
                  active={
                    selectedId === application.id ||
                    (!selectedId && selected?.id === application.id)
                  }
                  onSelect={() => setSelectedId(application.id)}
                />
              ))
            )}
          </div>
        </aside>

        <main className="min-w-0 bg-zinc-50/70 dark:bg-zinc-900/20">
          {selected ? (
            <ApplicationDetail
              application={selected}
              loading={actionLoading}
              onApprove={() =>
                void handleReview({ decision: "Approve" })
              }
              onDecision={setDialogDecision}
            />
          ) : (
            <div className="flex min-h-[640px] items-center justify-center px-6 text-center">
              <div>
                <ShieldCheck
                  className="mx-auto mb-3 size-12 text-zinc-300"
                  aria-hidden="true"
                />
                <p className="font-medium text-zinc-700 dark:text-zinc-200">
                  Chọn một hồ sơ để kiểm tra
                </p>
              </div>
            </div>
          )}
        </main>
      </div>

      <ReviewDecisionDialog
        open={dialogDecision != null}
        decision={dialogDecision}
        applicantName={selected?.fullName ?? "PT"}
        loading={actionLoading}
        onClose={() => setDialogDecision(null)}
        onConfirm={(reason) => {
          if (!dialogDecision) return;
          void handleReview({ decision: dialogDecision, reason });
        }}
      />
    </div>
  );
}

function SummaryCard({
  label,
  value,
  icon: Icon,
  tone,
}: {
  label: string;
  value: number;
  icon: typeof Clock3;
  tone: "amber" | "sky" | "emerald" | "red";
}) {
  const tones = {
    amber: "bg-amber-50 text-amber-700 dark:bg-amber-950/30 dark:text-amber-300",
    sky: "bg-sky-50 text-sky-700 dark:bg-sky-950/30 dark:text-sky-300",
    emerald:
      "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-300",
    red: "bg-red-50 text-red-700 dark:bg-red-950/30 dark:text-red-300",
  };
  return (
    <div className="flex items-center gap-3 rounded-xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950">
      <div className={cn("flex size-10 items-center justify-center rounded-lg", tones[tone])}>
        <Icon className="size-5" aria-hidden="true" />
      </div>
      <div>
        <p className="text-sm text-zinc-500">{label}</p>
        <p className="tabular-nums text-xl font-semibold text-zinc-900 dark:text-zinc-50">
          {value}
        </p>
      </div>
    </div>
  );
}

function ApplicationListItem({
  application,
  active,
  onSelect,
}: {
  application: CoachApplication;
  active: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={cn(
        "mb-1 flex min-h-24 w-full gap-3 rounded-xl border p-3 text-left transition-colors",
        active
          ? "border-emerald-200 bg-emerald-50 dark:border-emerald-900 dark:bg-emerald-950/30"
          : "border-transparent hover:border-zinc-200 hover:bg-zinc-50 dark:hover:border-zinc-800 dark:hover:bg-zinc-900",
      )}
    >
      <Avatar application={application} size="md" />
      <span className="min-w-0 flex-1">
        <span className="flex items-start justify-between gap-2">
          <span className="truncate text-sm font-semibold text-zinc-900 dark:text-zinc-50">
            {application.fullName || "Chưa cập nhật tên"}
          </span>
          <StatusBadge status={application.applicationStatus} />
        </span>
        <span className="mt-1 line-clamp-1 block text-xs text-zinc-500">
          {application.headline || application.specialty || "Chưa có tiêu đề"}
        </span>
        <span className="mt-2 flex items-center gap-1 text-xs text-zinc-500">
          <MapPin className="size-3.5" aria-hidden="true" />
          {application.city || "Chưa cập nhật"}
        </span>
      </span>
    </button>
  );
}

function ApplicationDetail({
  application,
  loading,
  onApprove,
  onDecision,
}: {
  application: CoachApplication;
  loading: boolean;
  onApprove: () => void;
  onDecision: (decision: CoachReviewDecision) => void;
}) {
  const canReview = application.applicationStatus === "PendingReview";
  return (
    <div className="flex min-h-full flex-col">
      <div className="border-b border-zinc-200 bg-white p-5 sm:p-6 dark:border-zinc-800 dark:bg-zinc-950">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start">
          <Avatar application={application} size="lg" />
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-balance text-xl font-bold text-zinc-900 dark:text-zinc-50">
                {application.fullName || "Chưa cập nhật tên"}
              </h2>
              <StatusBadge status={application.applicationStatus} />
            </div>
            <p className="mt-1 text-pretty text-sm font-medium text-zinc-700 dark:text-zinc-200">
              {application.headline || "Chưa cập nhật tiêu đề nghề nghiệp"}
            </p>
            <div className="mt-3 flex flex-wrap gap-x-5 gap-y-2 text-sm text-zinc-500">
              <span>{application.email}</span>
              <span>{application.phoneNumber || "Chưa có SĐT"}</span>
              <span className="flex items-center gap-1">
                <MapPin className="size-4" aria-hidden="true" />
                {application.city || "Chưa cập nhật"}
              </span>
            </div>
          </div>
          <div className="text-left text-xs text-zinc-500 sm:text-right">
            <p>Gửi lúc</p>
            <p className="mt-1 tabular-nums font-medium text-zinc-700 dark:text-zinc-200">
              {formatDateTime(application.submittedAt)}
            </p>
          </div>
        </div>
      </div>

      <div className="flex-1 space-y-5 p-5 sm:p-6">
        {application.reviewNote ? (
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
            <p className="font-semibold">Phản hồi xét duyệt gần nhất</p>
            <p className="mt-1 text-pretty">{application.reviewNote}</p>
          </div>
        ) : null}

        <DetailSection title="Thông tin cá nhân" icon={ShieldCheck}>
          <InfoGrid
            items={[
              ["Ngày sinh", formatDate(application.dateOfBirth)],
              ["Giới tính", genderLabel(application.gender)],
              ["Ngôn ngữ", application.languages.join(", ") || "—"],
              ["Khu vực", application.city || "—"],
            ]}
          />
          <DocumentLink
            label="Giấy tờ xác minh danh tính"
            url={application.identityDocumentUrl}
          />
        </DetailSection>

        <DetailSection title="Hồ sơ nghề nghiệp" icon={Award}>
          <InfoGrid
            items={[
              ["Kinh nghiệm", `${application.experienceYears} năm`],
              ["Trình độ học viên", application.clientLevels.join(", ") || "—"],
              ["Phong cách", application.coachingStyles.join(", ") || "—"],
            ]}
          />
          <div className="mt-4">
            <p className="text-xs font-medium uppercase text-zinc-500">Chuyên môn</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {application.specialty
                .split(",")
                .map((item) => item.trim())
                .filter(Boolean)
                .map((item) => (
                  <Badge key={item} variant="success">
                    {item}
                  </Badge>
                ))}
            </div>
          </div>
          <div className="mt-4">
            <p className="text-xs font-medium uppercase text-zinc-500">Giới thiệu</p>
            <p className="mt-2 whitespace-pre-line text-pretty text-sm leading-6 text-zinc-700 dark:text-zinc-200">
              {application.bio || "Chưa cập nhật"}
            </p>
          </div>
          {application.achievements ? (
            <div className="mt-4">
              <p className="text-xs font-medium uppercase text-zinc-500">Thành tích</p>
              <p className="mt-2 whitespace-pre-line text-pretty text-sm leading-6 text-zinc-700 dark:text-zinc-200">
                {application.achievements}
              </p>
            </div>
          ) : null}
        </DetailSection>

        <DetailSection title="Chứng chỉ chuyên môn" icon={FileBadge2}>
          {application.certificates.length === 0 ? (
            <p className="text-sm text-zinc-500">Chưa có chứng chỉ.</p>
          ) : (
            <div className="grid gap-3 lg:grid-cols-2">
              {application.certificates.map((certificate, index) => (
                <article
                  key={`${certificate.name}-${index}`}
                  className="flex gap-3 rounded-xl border border-zinc-200 p-3 dark:border-zinc-800"
                >
                  <a
                    href={certificate.imageUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="shrink-0"
                  >
                    <Image
                      src={certificate.imageUrl}
                      alt={`Ảnh chứng chỉ ${certificate.name}`}
                      width={80}
                      height={80}
                      unoptimized
                      className="size-20 rounded-lg object-cover"
                    />
                  </a>
                  <div className="min-w-0">
                    <h4 className="line-clamp-2 text-sm font-semibold text-zinc-900 dark:text-zinc-50">
                      {certificate.name}
                    </h4>
                    <p className="mt-1 text-xs text-zinc-500">{certificate.issuer}</p>
                    <p className="mt-2 text-xs text-zinc-500">
                      Mã: {certificate.credentialNumber || "—"}
                    </p>
                    <p className="mt-1 tabular-nums text-xs text-zinc-500">
                      {certificate.issuedDate || "—"} → {certificate.expiryDate || "Không thời hạn"}
                    </p>
                  </div>
                </article>
              ))}
            </div>
          )}
        </DetailSection>

        <DetailSection title="Hình ảnh hoạt động" icon={ImageIcon}>
          {application.galleryUrls.length === 0 ? (
            <p className="text-sm text-zinc-500">Chưa có hình ảnh.</p>
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
              {application.galleryUrls.map((url, index) => (
                <a key={url} href={url} target="_blank" rel="noreferrer">
                  <Image
                    src={url}
                    alt={`Ảnh hoạt động PT ${index + 1}`}
                    width={320}
                    height={320}
                    unoptimized
                    className="aspect-square w-full rounded-xl border border-zinc-200 object-cover dark:border-zinc-800"
                  />
                </a>
              ))}
            </div>
          )}
        </DetailSection>
      </div>

      <div className="sticky bottom-0 border-t border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950">
        {canReview ? (
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <Button
              variant="danger"
              disabled={loading}
              onClick={() => onDecision("Reject")}
            >
              Từ chối
            </Button>
            <Button
              variant="secondary"
              disabled={loading}
              onClick={() => onDecision("NeedsRevision")}
            >
              Yêu cầu bổ sung
            </Button>
            <Button loading={loading} onClick={onApprove}>
              <CheckCircle2 className="mr-2 size-4" aria-hidden="true" />
              Duyệt hồ sơ
            </Button>
          </div>
        ) : (
          <p className="text-right text-sm text-zinc-500">
            Hồ sơ này đã được xử lý lúc {formatDateTime(application.reviewedAt)}.
          </p>
        )}
      </div>
    </div>
  );
}

function DetailSection({
  title,
  icon: Icon,
  children,
}: {
  title: string;
  icon: typeof ShieldCheck;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-zinc-200 bg-white p-4 sm:p-5 dark:border-zinc-800 dark:bg-zinc-950">
      <h3 className="mb-4 flex items-center gap-2 text-base font-semibold text-zinc-900 dark:text-zinc-50">
        <Icon className="size-5 text-emerald-600" aria-hidden="true" />
        {title}
      </h3>
      {children}
    </section>
  );
}

function InfoGrid({ items }: { items: Array<[string, string]> }) {
  return (
    <dl className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {items.map(([label, value]) => (
        <div key={label}>
          <dt className="text-xs font-medium uppercase text-zinc-500">{label}</dt>
          <dd className="mt-1 text-sm text-zinc-800 dark:text-zinc-100">{value}</dd>
        </div>
      ))}
    </dl>
  );
}

function DocumentLink({ label, url }: { label: string; url: string | null }) {
  return (
    <div className="mt-4 flex items-center justify-between gap-3 rounded-xl bg-zinc-50 p-3 dark:bg-zinc-900">
      <div className="flex min-w-0 items-center gap-2">
        <FileBadge2 className="size-5 shrink-0 text-emerald-600" aria-hidden="true" />
        <span className="truncate text-sm font-medium text-zinc-800 dark:text-zinc-100">
          {label}
        </span>
      </div>
      {url ? (
        <a
          href={url}
          target="_blank"
          rel="noreferrer"
          className="shrink-0 text-sm font-medium text-emerald-700 hover:underline dark:text-emerald-300"
        >
          Xem ảnh
        </a>
      ) : (
        <span className="text-xs text-red-600">Chưa tải lên</span>
      )}
    </div>
  );
}

function Avatar({
  application,
  size,
}: {
  application: CoachApplication;
  size: "md" | "lg";
}) {
  const sizeClass = size === "lg" ? "size-20" : "size-12";
  if (application.avatarUrl) {
    return (
      <Image
        src={application.avatarUrl}
        alt={`Ảnh đại diện ${application.fullName}`}
        width={size === "lg" ? 80 : 48}
        height={size === "lg" ? 80 : 48}
        unoptimized
        className={cn(sizeClass, "shrink-0 rounded-xl object-cover")}
      />
    );
  }
  return (
    <div
      className={cn(
        sizeClass,
        "flex shrink-0 items-center justify-center rounded-xl bg-emerald-50 font-semibold text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300",
      )}
      aria-label={`Chưa có ảnh đại diện của ${application.fullName}`}
    >
      {(application.fullName || "PT").slice(0, 1).toUpperCase()}
    </div>
  );
}

function StatusBadge({ status }: { status: CoachApplicationStatus }) {
  const config: Record<
    CoachApplicationStatus,
    { label: string; variant: "success" | "warning" | "danger" | "neutral" | "info" }
  > = {
    Draft: { label: "Nháp", variant: "neutral" },
    PendingReview: { label: "Chờ duyệt", variant: "warning" },
    NeedsRevision: { label: "Cần bổ sung", variant: "info" },
    Approved: { label: "Đã duyệt", variant: "success" },
    Rejected: { label: "Từ chối", variant: "danger" },
    Suspended: { label: "Tạm ngưng", variant: "danger" },
  };
  const value = config[status] ?? config.Draft;
  return <Badge variant={value.variant}>{value.label}</Badge>;
}

function ReviewDecisionDialog({
  open,
  decision,
  applicantName,
  loading,
  onClose,
  onConfirm,
}: {
  open: boolean;
  decision: CoachReviewDecision | null;
  applicantName: string;
  loading: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
}) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [reason, setReason] = useState("");

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (open && !dialog.open) dialog.showModal();
    if (!open && dialog.open) dialog.close();
  }, [open, decision]);

  function closeDialog() {
    setReason("");
    onClose();
  }

  const isReject = decision === "Reject";
  const title = isReject ? "Từ chối hồ sơ PT" : "Yêu cầu bổ sung hồ sơ";
  const description = isReject
    ? `Hồ sơ của ${applicantName} sẽ không được kích hoạt.`
    : `Nêu rõ nội dung ${applicantName} cần sửa trước khi gửi lại.`;

  return (
    <dialog
      ref={dialogRef}
      role={isReject ? "alertdialog" : "dialog"}
      aria-labelledby="review-dialog-title"
      aria-describedby="review-dialog-description"
      onCancel={(event) => {
        event.preventDefault();
        closeDialog();
      }}
      onClose={closeDialog}
      className="m-auto w-[min(92vw,520px)] rounded-2xl border border-zinc-200 bg-white p-0 text-zinc-900 shadow-xl backdrop:bg-black/40 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-50"
    >
      <form
        onSubmit={(event) => {
          event.preventDefault();
          if (reason.trim()) onConfirm(reason.trim());
        }}
      >
        <div className="p-5 sm:p-6">
          <div
            className={cn(
              "mb-4 flex size-11 items-center justify-center rounded-xl",
              isReject
                ? "bg-red-50 text-red-600 dark:bg-red-950/30"
                : "bg-amber-50 text-amber-700 dark:bg-amber-950/30",
            )}
          >
            {isReject ? (
              <XCircle className="size-5" aria-hidden="true" />
            ) : (
              <CalendarDays className="size-5" aria-hidden="true" />
            )}
          </div>
          <h2 id="review-dialog-title" className="text-balance text-lg font-semibold">
            {title}
          </h2>
          <p
            id="review-dialog-description"
            className="mt-2 text-pretty text-sm text-zinc-500"
          >
            {description}
          </p>
          <div className="mt-5">
            <label htmlFor="review-reason" className="text-sm font-medium">
              Lý do <span className="text-red-600">*</span>
            </label>
            <Textarea
              id="review-reason"
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              placeholder="Nhập phản hồi rõ ràng để PT có thể điều chỉnh..."
              rows={5}
              className="mt-2"
              autoFocus
              required
            />
            {!reason.trim() ? (
              <p className="mt-2 text-xs text-zinc-500">
                Phản hồi này sẽ được hiển thị trên ứng dụng của PT.
              </p>
            ) : null}
          </div>
        </div>
        <div className="flex justify-end gap-2 border-t border-zinc-200 p-4 dark:border-zinc-800">
          <Button type="button" variant="secondary" onClick={closeDialog} disabled={loading}>
            Hủy
          </Button>
          <Button
            type="submit"
            variant={isReject ? "danger" : "primary"}
            loading={loading}
            disabled={!reason.trim()}
          >
            {isReject ? "Xác nhận từ chối" : "Gửi yêu cầu"}
          </Button>
        </div>
      </form>
    </dialog>
  );
}

function ApplicationListSkeleton() {
  return (
    <div className="space-y-2" aria-label="Đang tải hồ sơ PT">
      {[0, 1, 2, 3].map((item) => (
        <div key={item} className="flex gap-3 rounded-xl p-3">
          <div className="size-12 rounded-xl bg-zinc-200 dark:bg-zinc-800" />
          <div className="flex-1 space-y-2 py-1">
            <div className="h-4 w-2/3 rounded bg-zinc-200 dark:bg-zinc-800" />
            <div className="h-3 w-full rounded bg-zinc-100 dark:bg-zinc-900" />
            <div className="h-3 w-1/2 rounded bg-zinc-100 dark:bg-zinc-900" />
          </div>
        </div>
      ))}
    </div>
  );
}

function formatDate(value: string | null) {
  if (!value) return "—";
  const [year, month, day] = value.slice(0, 10).split("-");
  return year && month && day ? `${day}/${month}/${year}` : value;
}

function genderLabel(value: string) {
  if (value === "Male") return "Nam";
  if (value === "Female") return "Nữ";
  if (value === "Other") return "Khác";
  return "—";
}
