import { cn } from "@/lib/utils/cn";

/** Matches Flutter `AppColors.primary` in `frontend/lib/core/constants/app_colors.dart`. */
export const MENU_GREEN_PRIMARY = "#1B4332";

type MenuGreenLogoProps = {
  size?: number;
  className?: string;
};

/**
 * Logo giống splash screen Flutter: hộp xanh bo góc, nền trắng bên trong, icon lá.
 */
export function MenuGreenLogo({ size = 36, className }: MenuGreenLogoProps) {
  const outerRadius = size * 0.2;
  const innerSize = size * (80 / 120);
  const innerRadius = size * (16 / 120);
  const iconSize = size * (50 / 120);

  return (
    <div
      className={cn("relative flex shrink-0 items-center justify-center", className)}
      style={{
        width: size,
        height: size,
        borderRadius: outerRadius,
        backgroundColor: MENU_GREEN_PRIMARY,
        boxShadow: "0 10px 20px rgba(27, 67, 50, 0.2)",
      }}
    >
      <div
        className="flex items-center justify-center bg-white"
        style={{
          width: innerSize,
          height: innerSize,
          borderRadius: innerRadius,
        }}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          width={iconSize}
          height={iconSize}
          aria-hidden
        >
          <path
            fill={MENU_GREEN_PRIMARY}
            d="M12 3c-4.8 0-9 3.86-9 9c0 2.12.74 4.07 1.97 5.61L3 19.59 4.41 21l1.97-1.97A9.012 9.012 0 0 0 12 21c2.3 0 4.61-.88 6.36-2.64A8.95 8.95 0 0 0 21 12V3h-9zm3.83 9.26l-5.16 4.63c-.16.15-.41.14-.56-.01a.397.397 0 0 1-.04-.52l2.44-3.33-4.05-.4a.514.514 0 0 1-.3-.89l5.16-4.63c.16-.15.41-.14.56.01c.14.14.16.36.04.52l-2.44 3.33l4.05.4c.45.04.63.59.3.89z"
          />
        </svg>
      </div>
    </div>
  );
}
