import Link from "next/link";
import { PageHeader } from "@/components/layout/page-header";

const modules = [
  {
    href: "/dashboard/users",
    title: "Người dùng",
    description: "Quản lý tài khoản, role và trạng thái hoạt động",
  },
  {
    href: "/dashboard/foods",
    title: "Món ăn",
    description: "Tìm kiếm, thêm, sửa và xóa món ăn trong hệ thống",
  },
  {
    href: "/dashboard/ingredients",
    title: "Nguyên liệu",
    description: "Quản lý danh mục nguyên liệu cho công thức",
  },
  {
    href: "/dashboard/recipes",
    title: "Công thức",
    description: "Quản lý công thức nấu ăn và thành phần",
  },
];

export default function DashboardPage() {
  return (
    <div>
      <PageHeader
        title="Tổng quan"
        description="Trung tâm quản trị MenuGreen — chọn module để bắt đầu"
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {modules.map((module) => (
          <Link
            key={module.href}
            href={module.href}
            className="rounded-2xl border border-zinc-200 bg-white p-5 transition hover:border-emerald-300 hover:shadow-sm dark:border-zinc-800 dark:bg-zinc-950 dark:hover:border-emerald-800"
          >
            <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-50">
              {module.title}
            </h2>
            <p className="mt-2 text-sm leading-6 text-zinc-500 dark:text-zinc-400">
              {module.description}
            </p>
          </Link>
        ))}
      </div>
    </div>
  );
}
