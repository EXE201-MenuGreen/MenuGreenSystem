import { cn } from "@/lib/utils/cn";

type BadgeVariant = "success" | "warning" | "danger" | "neutral" | "info";

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  className?: string;
}

const variantClasses: Record<BadgeVariant, string> = {
  success:
    "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300",
  warning:
    "bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300",
  danger: "bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300",
  neutral: "bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300",
  info: "bg-sky-50 text-sky-700 dark:bg-sky-950/40 dark:text-sky-300",
};

export function Badge({
  children,
  variant = "neutral",
  className,
}: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        variantClasses[variant],
        className,
      )}
    >
      {children}
    </span>
  );
}

export function roleBadgeVariant(role: string): BadgeVariant {
  switch (role) {
    case "Admin":
      return "danger";
    case "Pro":
      return "info";
    case "Free":
      return "success";
    default:
      return "neutral";
  }
}
