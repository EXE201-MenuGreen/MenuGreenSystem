from pathlib import Path

path = Path(r'D:\University\Term8\EXE201\MenuGreenSystem\docs\01-deployment\DEPLOY_FIX_PLAN.md')
text = path.read_text(encoding='utf-8')

old = """|| 1 | `dotnet ef database update` chạy trong container runtime không có SDK | Migration fail, API có thể crash do DB schema chưa sẵn sàng |
|| 2 | `.env` dùng cả `:` và `__` | Config bị lỗi đọc, component không nhận giá trị |"""

new = """|| 1 | `.env` trên Lightsail lệch so với Doppler `prd` | API `menugreen_api` đang `unhealthy` do thiếu JWT + Redis connection string sai |
|| 1b | Migration đang chạy `dotnet ef database update` trong container runtime không có SDK | Migration fail im lặng hoặc không chạy đúng trong prod |
|| 2 | Redis chỉ có `REDIS_HOST`/`REDIS_PORT` riêng | `Program.cs` đọc `ConnectionStrings:Redis` → null |"""

if old not in text:
    raise SystemExit('old block not found')

path.write_text(text.replace(old, new), encoding='utf-8')
