# Chạy MenuGreen APK với backend trong cùng mạng LAN

Tài liệu này dùng cho trường hợp:

- backend chạy trên một máy tính Windows;
- điện thoại của bạn và điện thoại của bạn bè dùng chung Wi-Fi/LAN với máy tính;
- APK được build bằng GitHub Actions từ nhánh `free-user-workflow`.

## 1. Yêu cầu

Trên máy chạy backend:

- Git;
- Docker Desktop;
- đã clone repository `MenuGreenSystem`;
- đang checkout nhánh `free-user-workflow`.

Điện thoại Android cần cho phép cài ứng dụng từ file APK.

## 2. Lấy IP LAN của máy chạy backend

Mở PowerShell:

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike '127.*' -and
    $_.IPAddress -notlike '169.254.*'
  } |
  Select-Object InterfaceAlias, IPAddress
```

Chọn IP của `Wi-Fi` hoặc `Ethernet`. Ví dụ IP tại thời điểm viết tài liệu:

```text
192.168.100.211
```

IP này có thể thay đổi khi máy kết nối lại Wi-Fi.

## 3. Cấu hình và chạy backend

Mở PowerShell tại thư mục gốc repository:

```powershell
git switch free-user-workflow
Copy-Item backend\.env.example backend\.env
notepad backend\.env
```

Trong `backend\.env`, tối thiểu hãy thay:

```dotenv
POSTGRES_PASSWORD=mat_khau_local_cua_ban
JWT_SECRET_KEY=chuoi_bi_mat_local_dai_hon_32_ky_tu
ALLOWED_ORIGINS=*
REDIS_CONNECTION_STRING=
```

Không commit file `backend\.env`.

Bật Docker Desktop, chờ Docker Engine sẵn sàng, rồi chạy:

```powershell
docker compose -f backend\docker-compose.yml up -d --build postgres api
```

Kiểm tra trạng thái:

```powershell
docker compose -f backend\docker-compose.yml ps
docker compose -f backend\docker-compose.yml logs --tail 100 api
```

Kiểm tra API trên máy:

```powershell
Invoke-RestMethod http://localhost:5000/health/live
```

Kiểm tra bằng IP LAN:

```powershell
Invoke-RestMethod http://192.168.100.211:5000/health/live
```

Thay `192.168.100.211` bằng IP LAN thực tế của máy.

## 4. Mở cổng Windows Firewall nếu điện thoại không kết nối được

Mở PowerShell bằng quyền Administrator:

```powershell
New-NetFirewallRule `
  -DisplayName "MenuGreen Backend LAN 5000" `
  -Direction Inbound `
  -Action Allow `
  -Protocol TCP `
  -LocalPort 5000 `
  -RemoteAddress LocalSubnet `
  -Profile Any
```

Rule trên chỉ nhận kết nối từ subnet hiện tại. Không nên chạy backend LAN trên Wi-Fi
công cộng; tốt nhất hãy dùng mạng riêng mà bạn tin cậy.

Từ một thiết bị khác trong cùng mạng, mở:

```text
http://192.168.100.211:5000/health/live
```

Nếu endpoint health trả về dữ liệu thì kết nối LAN đã hoạt động.

Database mới sẽ được tạo schema bằng EF migrations và ban đầu chưa có dữ liệu demo.
Không chạy `backend\run_seed_data.ps1` trên database đang có dữ liệu quan trọng vì
các SQL seed cũ có câu lệnh xóa và tạo lại bảng.

## 5. Build APK bằng GitHub Actions

Workflow nằm tại:

```text
.github/workflows/android-apk.yml
```

Sau khi workflow đã được commit và push lên GitHub:

1. Mở repository trên GitHub.
2. Chọn tab **Actions**.
3. Chọn workflow **Android APK - LAN Backend**.
4. Chọn **Run workflow**.
5. Chọn nhánh `free-user-workflow`.
6. Nhập backend URL, ví dụ:

   ```text
   http://192.168.100.211:5000/api
   ```

7. Chạy workflow và chờ job **Build release APK** hoàn tất.
8. Mở workflow run, tải artifact có tên dạng `MenuGreen-LAN-APK-...`.
9. Giải nén artifact để lấy file APK.

Nếu dùng bản đồ Goong, thêm repository secret `GOONG_API_KEY`. Workflow vẫn build
được khi không có secret này, nhưng tính năng bản đồ Goong sẽ không hoạt động đầy đủ.

## 6. Cài APK cho bạn và bạn bè

1. Kết nối điện thoại vào cùng Wi-Fi với máy chạy backend.
2. Tắt VPN nếu VPN chặn truy cập mạng LAN.
3. Chép file APK vào điện thoại.
4. Cho phép trình quản lý file cài ứng dụng không rõ nguồn gốc.
5. Cài APK và mở MenuGreen.

Bạn có thể gửi cùng file APK cho nhiều người trong cùng mạng. Máy tính chạy backend
phải luôn bật, Docker Desktop phải chạy, và container `menugreen-api` phải ở trạng
thái `healthy`.

## 7. Khi đổi Wi-Fi hoặc IP LAN

URL backend được nhúng vào APK tại thời điểm build. Nếu IP máy chạy backend đổi:

1. lấy IP LAN mới;
2. chạy lại workflow với URL mới;
3. tải và cài APK mới.

Không dùng `localhost` hoặc `127.0.0.1` trong APK vì các địa chỉ đó trỏ tới chính
điện thoại, không phải máy tính chạy backend.

## 8. Dừng hoặc chạy lại backend

Dừng backend nhưng giữ nguyên dữ liệu PostgreSQL:

```powershell
docker compose -f backend\docker-compose.yml stop api postgres
```

Chạy lại:

```powershell
docker compose -f backend\docker-compose.yml start postgres api
```

Build lại sau khi sửa code backend:

```powershell
docker compose -f backend\docker-compose.yml up -d --build api
```

Không chạy `docker compose down -v` nếu muốn giữ dữ liệu database.

## 9. Xử lý lỗi nhanh

### Điện thoại báo không kết nối được backend

- xác nhận điện thoại và máy tính cùng Wi-Fi;
- kiểm tra lại IP LAN;
- mở `http://IP_LAN:5000/health/live` trên điện thoại;
- kiểm tra Windows Firewall;
- kiểm tra container bằng `docker compose -f backend\docker-compose.yml ps`;
- build lại APK nếu IP đã thay đổi.

### Workflow không build được

- kiểm tra job log trong tab Actions;
- xác nhận file `frontend/android/app/google-services.json` có trong nhánh;
- xác nhận URL nhập vào có dạng `http://IP:5000/api`;
- chạy lại workflow sau khi lỗi tạm thời của runner hoặc mạng đã hết.
