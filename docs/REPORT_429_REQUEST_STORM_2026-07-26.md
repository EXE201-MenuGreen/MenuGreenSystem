# Báo cáo phân tích 429 Too Many Requests và request storm

**Hệ thống:** MenuGreen  
**Ngày kiểm tra:** 26/07/2026 (UTC+7)  
**Nhánh:** `free-user-workflow`  
**Phạm vi:** Flutter frontend, ASP.NET Core backend, Nginx, Cloudflare và AWS Lightsail

## 1. Kết luận điều hành

429 hiện tại không nên được xử lý bằng cách tăng cấu hình AWS trước. Qua kiểm tra mã nguồn, có một chuỗi feedback loop đủ khả năng tạo đúng hiện tượng request lặp trong vài trăm mili giây:

1. Một API trả 500/502/503/504 làm frontend đánh dấu server mất kết nối.
2. Một request khác trả 200–499, kể cả 401 hoặc 429, lại bị coi là kết nối đã phục hồi.
3. Sự kiện `onReconnected` được phát.
4. `MealPlanProvider` lập tức tải lại plans, `/MealPlan/dashboard` và `/MealPlan/streaks`.
5. Dashboard lỗi sẽ gọi thêm fallback `/user-meal-plans/adherence`.
6. Các lần tải không có single-flight guard nên nhiều chu kỳ có thể chạy chồng lên nhau.

Request storm còn bị khuếch đại bởi:

- Hai tầng `IndexedStack` khởi tạo cả tab đang bị ẩn.
- Nhiều repository/`ApiClient` độc lập nên cache không được chia sẻ.
- Retry tối đa ba lần cho 502/503/504/timeout.
- 401 được refresh token và phát lại request.
- Fallback subscription có thể biến một lời gọi thành ba API call.
- Rate limit Nginx và ASP.NET đang có nguy cơ tính theo IP của Cloudflare/Nginx thay vì người dùng thật.

**Mức độ:** P0 – có thể gây tự khuếch đại tải, làm backend đã lỗi càng khó phục hồi.

## 2. Tình trạng production tại thời điểm kiểm tra

Kiểm tra read-only lúc khoảng **17:52 ngày 26/07/2026 (UTC+7)**:

| Endpoint | Kết quả |
|---|---:|
| `https://api.menugreen.food/health/live` | 200 |
| `https://api.menugreen.food/health` | 200 |
| `https://api.menugreen.food/health/ready` | 502 |
| `https://api.menugreen.food/api/Food` | 502 |

Response đi qua Cloudflare (`Server: cloudflare`, có `CF-RAY`). Kết quả này cho thấy Nginx/Cloudflare vẫn truy cập được, nhưng API upstream tại thời điểm kiểm tra không ready hoặc không thể được Nginx kết nối.

Hai endpoint đang trả 200 không phản ánh đúng trạng thái API:

- `backend/nginx/nginx.conf:113-120`: `/health` có `return 200` tĩnh, nên `proxy_pass` không thực sự kiểm tra backend.
- `backend/nginx/nginx.conf:130-133`: `/health/live` cũng trả 200 tĩnh từ Nginx.
- Chỉ `/health/ready` thực sự proxy vào ASP.NET và hiện trả 502.

Vì vậy dashboard giám sát có thể báo xanh trong khi API thật đang lỗi.

### 2.1. Bằng chứng từ Network timeline do người dùng cung cấp

Ảnh Network cho thấy chuỗi sau lặp lại liên tục:

| Thời điểm | Request | Status |
|---|---|---:|
| 16:47:15.647 | `/api/Food` | 401 |
| 16:47:15.648 | `/api/user-meal-plans/adherence` | 200 |
| 16:47:15.775 | `/api/MealPlan/dashboard` | 500 |
| 16:47:15.777 | `/api/MealPlan/streaks` | 500 |
| 16:47:15.971 | `/api/Food` | 401 |
| 16:47:15.974 | `/api/user-meal-plans/adherence` | 200 |
| 16:47:16.017 | `/api/MealPlan/dashboard` | 500 |
| 16:47:16.018 | `/api/MealPlan/streaks` | 500 |
| 16:47:16.249 | `/api/Food` | 401 |
| 16:47:16.254 | `/api/user-meal-plans/adherence` | 200 |
| 16:47:16.331 | `/api/MealPlan/dashboard` | 500 |
| 16:47:16.333 | `/api/MealPlan/streaks` | 500 |
| 16:47:16.556 | `/api/Food` | 429 |
| 16:47:16.562 | `/api/user-meal-plans/adherence` | 200 |
| 16:47:16.606 | `/api/MealPlan/dashboard` | 429 |
| 16:47:16.607 | `/api/MealPlan/streaks` | 500 |
| 16:47:16.848–17.076 | Food, adherence, dashboard, streaks | 429 |

Dashboard được gọi lại vào khoảng 242–335 ms/lần. Chỉ riêng bốn endpoint trong ảnh đã tạo khoảng 12 request trước 429 đầu tiên, trong chưa đầy một giây và chưa tính các request nằm ngoài vùng ảnh.

Pattern này củng cố trực tiếp feedback loop:

1. Dashboard/streaks trả 500.
2. Dashboard fallback sang adherence và nhận 200.
3. Server failure đồng thời kích hoạt health probe `/Food`, nhận 401.
4. Cả adherence 200 và health probe 401 đều có thể chuyển trạng thái về `connected`.
5. Sự kiện reconnect gọi lại dashboard/streaks.
6. Sau vài vòng, limiter bắt đầu trả 429 cho toàn bộ nhóm endpoint.

Đây không giống retry nội bộ thông thường của `ApiErrorMiddleware`, vì:

- Middleware không retry status 500.
- Retry transient đầu tiên của middleware phải chờ khoảng một giây.
- Ảnh cho thấy cả nhóm API được khởi tạo lại chỉ sau khoảng 250–350 ms.

Việc các response 401/429 có kiểu hiển thị khác response JSON 200/500 là một dấu hiệu rejection có thể xảy ra trước controller, nhưng chưa đủ để phân biệt chắc chắn Nginx, ASP.NET rate limiter hay Cloudflare. Cần đối chiếu `CF-RAY`, response headers và log cùng thời điểm.

## 3. Nguyên nhân gốc phía Frontend

### P0.1 – Feedback loop giữa lỗi API và sự kiện reconnect

**Bằng chứng**

- `frontend/lib/core/network/api_client.dart:226-230`
  - Status 200–499 đều gọi `reportConnectionSuccess()`.
  - Status từ 500 trở lên gọi `reportConnectionFailure()`.
- `frontend/lib/core/network/network_connectivity_service.dart:30-43`
  - Failure chuyển sang `reconnecting`.
  - Success chuyển về `connected` và phát `onReconnected`.
- `frontend/lib/features/meal_plan/providers/meal_plan_provider.dart:14-17`
  - Mỗi sự kiện reconnect gọi `refreshOnReconnected()`.
- `frontend/lib/features/meal_plan/providers/meal_plan_provider.dart:597-601`
  - Reconnect gọi lại `loadAllForHome()`.
- `frontend/lib/features/meal_plan/providers/meal_plan_provider.dart:183-187`
  - Mỗi lần load gọi đồng thời plans, dashboard và streaks.
- `frontend/lib/features/meal_plan/providers/meal_plan_provider.dart:127-141`
  - Dashboard lỗi sẽ gọi thêm adherence.

**Chuỗi lỗi điển hình**

```text
dashboard 500
  -> connection = reconnecting
  -> request khác trả 401/429/200
  -> connection = connected
  -> onReconnected
  -> loadAllForHome
  -> dashboard + streaks
  -> dashboard lỗi
  -> adherence fallback
  -> chu kỳ tiếp tục
```

401 và 429 chứng minh server có phản hồi HTTP, nhưng không chứng minh phiên đăng nhập hoặc API nghiệp vụ đã phục hồi. Không nên dùng chúng để phát sự kiện reload toàn ứng dụng.

### P0.2 – Dùng `/Food` có xác thực làm health-check

**Bằng chứng**

- `frontend/lib/core/network/api_endpoints.dart:44`: `health => '$baseUrl/Food'`.
- `frontend/lib/core/network/network_connectivity_service.dart:55-63`: ping health bằng HTTP GET không có Authorization.
- `backend/MenuGreen.API/Controllers/FoodController.cs:13-16`: toàn bộ `FoodController` yêu cầu `UserOnly`.

Khi API hoạt động bình thường, health-check thô có thể nhận 401. Code hiện coi mọi status dưới 500 là thành công và phát reconnect. Khi API đang lỗi, `/Food` còn bị retry bởi client nghiệp vụ và xuất hiện dày đặc trên Network tab.

### P0.3 – Eager-loading tất cả tab ẩn

`MainScreen` khởi động ở Home nhưng dùng `IndexedStack`:

- `frontend/lib/features/main/views/main_screen.dart:148-151`
  - Discover, Meal Plan, Home, History và Profile đều được inflate ngay.

Hệ quả lúc cold start:

- Discover gọi favorites, allergy và `/Food`.
- Home gọi profile, subscription, daily summary và adherence.
- History gọi đồng thời daily summary và hai dashboard thống kê.
- Profile gọi profile và subscription.
- Smart Meal Plan Router tiếp tục khởi tạo workspace.

Router Meal Plan lại có một `IndexedStack` thứ hai:

- `frontend/lib/features/meal_plan/views/smart_meal_plan_router_screen.dart:170-176`
  - `MealPlanScreen`, `OfficeMealPlanScreen` và `GymerHubScreen` đều được khởi tạo dù chưa được chọn.

Trong đó:

- `MealPlanScreen` gọi plans + dashboard + streaks tại `meal_plan_screen.dart:34-38`.
- `OfficeMealPlanScreen` gọi bốn luồng ngay trong `initState` tại `office_meal_plan_screen.dart:55-62`.
- Office gọi thêm dashboard tại `office_meal_plan_screen.dart:238-252`.
- Office còn gọi API trước khi kết quả kiểm tra quyền Office hoàn tất.

Theo các đường code hiện tại, một cold start có thể tạo hơn 20 logical API calls tùy dữ liệu và entitlement, trước khi tính 401 replay, retry và fallback.

### P0.4 – Không có request dedup/single-flight ở các API chính

- `MealPlanProvider.loadAllForHome()` không kiểm tra một lần load khác đang chạy.
- `loadTodayDashboard()` và `loadStreaks()` cũng không có in-flight guard.
- Listener reconnect không `await` hoặc khóa lần refresh trước.
- Cache dashboard/streak chỉ được ghi sau khi request thành công.
- Cache nằm trên từng instance `MealPlanRepository`, không dùng chung toàn app.
- `getAdherence()` không có cache.
- Có nhiều nơi tạo `MealPlanRepository()` và `FoodDiscoveryRepository()` riêng.

Do đó hai request cùng URL bắt đầu trước khi request đầu hoàn tất vẫn cùng đi tới backend. Khi backend lỗi, không có stale cache hoặc negative cache để ngăn gọi lặp.

### P1.1 – Retry khuếch đại tải

`frontend/lib/core/middleware/error_middleware.dart:47-115`:

- Tổng cộng tối đa ba attempt cho 502/503/504, timeout và lỗi socket.
- Delay cố định theo attempt (1 giây, 2 giây), không có jitter.
- Middleware dùng chung cho GET, POST, PUT, PATCH và DELETE.

`frontend/lib/core/network/api_client.dart:193-211`:

- Mỗi 401 có thể refresh token rồi replay request một lần.
- Refresh token có single-flight toàn cục; đây là điểm tốt.
- Tuy nhiên sau một refresh chung, mọi request 401 ban đầu vẫn tự replay, nên số request nghiệp vụ vẫn tăng gấp đôi.

429 hiện không bị middleware retry trực tiếp, nhưng các lifecycle callback và reconnect event vẫn có thể tạo request mới ngay sau 429. Client cũng chưa đọc `Retry-After`.

### P1.2 – Fallback tạo thêm request khi backend đã lỗi

`UserSubscriptionRepository.getFeatureAccess()`:

1. Gọi entitlements.
2. Nếu lỗi, gọi active subscriptions.
3. Nếu active lỗi, gọi current subscription.

Nhiều widget hidden gọi repository này đồng thời. Khi API 401/500, một lời gọi logic có thể trở thành ba request, chưa tính retry.

Dashboard cũng fallback sang adherence ngay khi dashboard lỗi. Với 401, 429 hoặc server outage, fallback gần như chắc chắn thất bại và chỉ làm tăng tải.

### Nhận định về `useEffect`

Frontend chính là Flutter, không phải React. Không phát hiện `useEffect` loop ở luồng mobile. Tương đương `useEffect` gây vấn đề ở đây là:

- `initState` của tab hidden.
- `notifyListeners` kết hợp listener reconnect.
- `IndexedStack` eager initialization.
- Callback reload sau điều hướng/thao tác.

Discover đã có debounce 450 ms và generation guard. Đây không phải nguồn chính của request storm, dù request cũ chưa được hủy ở tầng HTTP.

## 4. Nguyên nhân và rủi ro phía Backend/Nginx

### P0.5 – ASP.NET rate limit có thể gom toàn bộ người dùng vào một proxy IP

`backend/MenuGreen.API/Program.cs:301-319` đặt global limit 100 request/phút theo:

```csharp
httpContext.Connection.RemoteIpAddress
```

Nhưng:

- Nginx đứng trước ASP.NET.
- Nginx có gửi `X-Forwarded-For`.
- `Program.cs` không cấu hình hoặc gọi `UseForwardedHeaders()`.
- Container publish port qua host nên ASP.NET nhiều khả năng thấy IP Nginx/bridge thay vì client.

Kết quả: nhiều hoặc toàn bộ user có thể dùng chung một rate-limit partition 100 request/phút.

### P0.6 – Rate limiter chạy trước authentication

`backend/MenuGreen.API/Program.cs:565-570`:

```text
UseRateLimiter
UseAuthentication
UseAuthorization
```

Các policy muốn lấy `NameIdentifier` sẽ chưa có authenticated user khi limiter chạy, nên fallback về IP.

Đặc biệt `AuthController` áp `AuthPolicy` cho cả controller:

- 5 request / 2 phút / IP.
- Bao gồm `/Auth/refresh-token`.
- Nếu IP đang là IP proxy dùng chung, chỉ vài phiên refresh có thể khóa refresh token cho tất cả user phía sau proxy.

Refresh thất bại làm các API tiếp tục 401 và góp phần tạo storm.

### P0.7 – Nginx cũng rate limit theo IP Cloudflare thay vì client thật

`backend/nginx/nginx.conf:40-43`:

- API: 10 request/giây.
- Burst: 20.
- Limit connection: 10.

`backend/nginx/nginx.conf:87-89` áp dụng cho toàn server.

Nginx dùng `$binary_remote_addr`, nhưng traffic production đi qua Cloudflare và chưa có:

- `set_real_ip_from` cho dải IP Cloudflare.
- `real_ip_header CF-Connecting-IP`.

Nginx có thể đang limit theo IP Cloudflare edge, khiến nhiều client bị gom chung.

### P1.3 – Hai tầng limiter khó xác định nguồn 429

429 có thể đến từ:

1. Cloudflare rule nếu dashboard có cấu hình ngoài repo.
2. Nginx `limit_req`.
3. ASP.NET Core global/named policy.
4. AWS WAF hoặc API Gateway nếu có hạ tầng ngoài repo.

Repo hiện thể hiện đường đi **Cloudflare → Nginx → Docker ASP.NET trên AWS Lightsail**, không thấy cấu hình API Gateway/WAF. Vì vậy không đủ bằng chứng để kết luận AWS là nơi phát 429.

ASP.NET hiện chỉ đặt status 429, chưa có:

- `Retry-After`.
- JSON body chỉ rõ limiter/source.
- Log `OnRejected`.
- Correlation ID để đối chiếu.

### P1.4 – Endpoint dashboard/streak tạo tải DB đáng kể

`MealPlanService.GetDashboardAsync()`:

- Tải headers, items và meal logs.
- Sau đó lặp từng item và `await MapItemAsync(item)`.
- `MapItemAsync` tiếp tục query food/recipe/macros.
- Đây là mẫu N+1 theo số item.

`MealPlanService.GetStreaksAsync()`:

- Tải toàn bộ meal logs của user.
- Tải toàn bộ plan headers và toàn bộ plan items.
- Sau đó mới tính streak và 7-day adherence trong bộ nhớ.

Khi frontend lặp request, các endpoint này làm CPU/DB tăng nhanh, dễ dẫn tới 500/502 và tiếp tục kích hoạt feedback loop.

Redis/`IDistributedCache` đã được đăng ký trong `Program.cs`, nhưng chưa được dùng để cache dashboard, streak, adherence hoặc Food search.

### P1.5 – External health-check đang báo xanh giả

Nginx trả 200 tĩnh cho `/health` và `/health/live`. Uptime monitor hoặc deploy check đi qua domain có thể không phát hiện API container/upstream đã lỗi.

Điều này làm thời gian phát hiện sự cố kéo dài và frontend tiếp tục gửi request vào một origin không phục vụ được.

## 5. Giải pháp đề xuất

## 5.1. P0 – Hotfix frontend

### A. Tách network reachability khỏi API/application health

1. Đổi health endpoint từ `/api/Food` sang `/health/ready` hoặc một endpoint anonymous chuyên dụng.
2. Chỉ coi 2xx từ health endpoint là healthy.
3. Không gọi `reportConnectionSuccess()` từ response 401, 403 hoặc 429.
4. Không phát `onReconnected` chỉ vì một request song song trả status khác 500.
5. Thêm single-flight cho health probe và cooldown 30–60 giây.
6. Chỉ phát reconnect sau khi đã ở trạng thái unavailable đủ lâu và có ít nhất một hoặc hai health probe 2xx thành công.

Nên hợp nhất hai hệ thống đang cùng theo dõi mạng:

- `NetworkConnectivityService`.
- `NetworkStatusProvider`.

### B. Khóa các lần load trùng

Thêm vào `MealPlanProvider`:

- `_homeLoadInFlight`.
- `_lastHomeLoadedAt`.
- TTL tối thiểu 15–30 giây.
- `forceRefresh` chỉ dành cho pull-to-refresh hoặc mutation thành công.
- Reconnect event trả về cùng Future nếu load trước chưa xong.

Áp dụng single-flight theo key cho:

- `GET /Food?...`
- `GET /MealPlan/dashboard?date=...`
- `GET /MealPlan/streaks`
- `GET /user-meal-plans/adherence?date=...`
- Subscription entitlement.

### C. Lazy-load tab

1. `MainScreen`: chỉ tạo Home ở cold start; tạo Discover/Meal Plan/History/Profile lần đầu user chọn tab.
2. `SmartMealPlanRouterScreen`: render bằng `switch` theo mode hiện tại, không dùng `IndexedStack` chứa cả ba workspace.
3. Không khởi tạo Office/Gymer trước khi xác nhận entitlement.
4. Office chỉ gọi API Office sau khi access là true.

Mục tiêu cold start tại Home:

- `/Food`: 0 request.
- `/MealPlan/dashboard`: 0 request nếu Home chưa cần dashboard.
- `/MealPlan/streaks`: 0 request.
- `/user-meal-plans/adherence`: tối đa 1 request, hoặc 0 nếu dùng bootstrap API.

### D. Sửa retry

- Retry tự động chỉ cho GET/HEAD idempotent và lỗi thực sự transient.
- Không retry 400/401/403/404.
- Với 429: đọc `Retry-After`, không gọi lại trước thời điểm đó.
- Dùng exponential backoff với full jitter.
- Có retry budget/circuit breaker toàn app để backend lỗi không khiến mọi repository cùng retry.
- POST/PATCH/DELETE chỉ retry khi có idempotency key hoặc chứng minh request chưa được server xử lý.
- Khi refresh token thất bại: clear session, điều hướng login và hủy/không phát lại các request authenticated còn chờ.

### E. Chia sẻ client và cache

- Inject một `ApiClient`/repository dùng chung qua Provider/DI.
- Cache parsed model theo user + URL + query.
- Cho phép trả stale data khi 5xx/429 để UI vẫn hoạt động.
- Invalidate cache sau mutation liên quan thay vì reload toàn bộ.

## 5.2. P0 – Hotfix backend và Nginx

### A. Sửa IP thật và thứ tự middleware

1. Nginx chỉ tin Cloudflare IP ranges và dùng:

```nginx
real_ip_header CF-Connecting-IP;
real_ip_recursive on;
```

2. ASP.NET cấu hình `ForwardedHeadersOptions` với đúng trusted proxy/network.
3. Gọi `UseForwardedHeaders()` trước logging, authentication và rate limiter.
4. Đưa `UseAuthentication()` trước limiter nếu policy partition theo user.
5. Bind API port vào loopback (`127.0.0.1:5000:5000`) để client không bypass Nginx và spoof forwarded headers.

Không được tin mọi `X-Forwarded-For` từ Internet.

### B. Thiết kế lại rate limit

- Authenticated API: partition theo `userId`, có thêm coarse per-IP abuse guard.
- Anonymous Auth/OTP: partition theo IP client thật + route.
- Refresh token nên có policy riêng, không dùng chung bucket 5/2 phút với login/OTP.
- Health endpoint phải được exclude hoặc có bucket riêng.
- Chọn một tầng làm limiter nghiệp vụ chính; các tầng ngoài chỉ bảo vệ DDoS/coarse abuse.
- Bổ sung `OnRejected`:
  - `Retry-After`.
  - JSON error code.
  - limiter name.
  - correlation/request ID.
  - structured log.

Không tăng limit trước khi sửa partition key. Tăng limit khi mọi user đang dùng chung một proxy IP chỉ che lỗi và tăng chi phí.

### C. Sửa health-check

- `/health/live`: proxy tới ASP.NET liveness thật, không trả tĩnh từ Nginx.
- `/health/ready`: proxy tới ASP.NET và kiểm tra dependency cần thiết.
- Nếu cần kiểm tra riêng Nginx, tạo `/edge/health` với tên rõ ràng.
- Uptime/deployment monitor phải dùng `/health/ready`.

### D. Khôi phục production hiện tại

Vì `/health/ready` đang 502:

1. Kiểm tra `docker compose ps`.
2. Kiểm tra `docker logs menugreen_api --since 30m`.
3. Từ server gọi `curl -i http://127.0.0.1:5000/health/ready`.
4. Kiểm tra container restart/OOM và migration startup.
5. Kiểm tra `docker stats`, RAM, CPU và DB connection.
6. Chỉ sau khi upstream ready mới đánh giá lại 429.

## 5.3. P1 – Cache, dedup và batch API phía backend

### Redis cache đề xuất

| Dữ liệu | Cache key gợi ý | TTL ban đầu |
|---|---|---:|
| Dashboard | `meal-dashboard:{userId}:{date}` | 15–30 giây |
| Streak | `meal-streak:{userId}` | 1–5 phút |
| Adherence | `meal-adherence:{userId}:{date}` | 30–60 giây |
| Food search | user/profile-version + normalized query | 1–5 phút |
| Entitlements | `entitlement:{userId}` | 1–5 phút |

Yêu cầu:

- Có stampede protection/single-flight ở server.
- Invalidate dashboard/adherence/streak sau meal log hoặc meal-plan mutation.
- Không dùng cache key thiếu user/allergy profile cho dữ liệu cá nhân hóa.

### Batch/bootstrap API

Tạo một endpoint nhỏ cho Home, ví dụ:

```text
GET /api/Home/bootstrap?date=2026-07-26
```

Chỉ trả dữ liệu Home thực sự cần:

- Daily nutrition summary.
- Meal-plan summary/adherence.
- Entitlement summary.
- Unread notification count nếu cần.

Dashboard hiện đã có planned/actual calories và completed/total meals, nên có thể bỏ request adherence riêng nếu response được chuẩn hóa.

Batch API giảm số permit HTTP nhưng phải tối ưu query bên trong; không chỉ gói nhiều query N+1 vào một controller.

### Tối ưu query

- Dashboard: batch food/recipe/macro cho toàn bộ item, tương tự hướng `MapAsync` đã làm ở nơi khác.
- Streak: query aggregate theo ngày hoặc duy trì bảng daily aggregate; không tải toàn bộ lịch sử vào memory mỗi lần.
- Dùng projection và `AsNoTracking()` cho read-only.
- Thêm index theo `UserId`, `LoggedAt`, `MealPlanId`, `PlannedDate`, `MealPlanItemId`.
- Đo query count và duration bằng OpenTelemetry/EF logging trước và sau.

### Conditional request

Với GET thay đổi chậm:

- Trả `ETag`.
- Client gửi `If-None-Match`.
- Có thể dùng `Cache-Control: private` cho dữ liệu theo user.

Không cache public ở CloudFront/Cloudflare cho response chứa dữ liệu user trừ khi cache key và authorization đã được thiết kế, kiểm thử rõ ràng.

## 5.4. P1 – AWS/Cloudflare và quan sát hệ thống

AWS Lightsail dùng CPU burst. Cần theo dõi:

- `CPUUtilization`.
- `BurstCapacityTime`.
- `BurstCapacityPercentage`.
- Network in/out.
- Container restart/OOM.
- DB connection pool và query latency.

Không nên thêm AWS WAF chỉ để chữa request loop. Nếu sau này dùng WAF:

- Chạy rate rule ở Count mode trước.
- Aggregate theo forwarded IP đã xác minh hoặc custom key phù hợp.
- Scope theo URI/method.
- Không aggregate theo IP proxy cuối.

Cloudflare:

- Kiểm tra Security Events/Rate Limiting có rule ngoài repo không.
- Dùng `CF-Connecting-IP` chỉ sau khi origin giới hạn traffic đến Cloudflare.
- Ghi log `CF-RAY`, client IP đã chuẩn hóa và request ID.

Nginx:

- Tìm 429 do `limit_req` trong error log.
- Log upstream status và request time.
- Thêm biến `limit_req_status` vào access log nếu phiên bản hỗ trợ.

ASP.NET:

- Counter theo endpoint/status/user partition.
- Log rate-limit rejection.
- Prometheus metric cho request count, duration, in-flight, retry và DB duration.
- Correlation ID xuyên Cloudflare → Nginx → ASP.NET.

## 6. Cách xác định chính xác tầng phát 429

### Trên server

```bash
sudo grep -i "limiting requests" /var/log/nginx/error.log
sudo tail -n 500 /var/log/nginx/access.log | grep ' 429 '
docker logs menugreen_api --since 1h 2>&1 | grep -E '429|RateLimit|TooMany'
curl -i http://127.0.0.1:5000/health/ready
```

### Trong Network tab

Lưu lại cho từng 429:

- Response headers.
- Response body.
- `CF-RAY`.
- `Retry-After`.
- `x-amzn-requestid`/`x-amzn-errortype` nếu có.
- Thời điểm và initiator.

Nhận dạng:

| Dấu hiệu | Khả năng |
|---|---|
| Nginx error log có `limiting requests` cùng thời điểm | Nginx |
| App log `OnRejected`/limiter name | ASP.NET |
| Cloudflare Security Event trùng `CF-RAY` | Cloudflare |
| Có `x-amzn-*` và resource AWS tương ứng | API Gateway/WAF/AWS edge |

Chỉ có `Server: cloudflare` chưa đủ kết luận Cloudflare tạo 429, vì response từ origin cũng đi xuyên Cloudflare.

## 7. Kế hoạch triển khai ưu tiên

### Trong ngày – P0

1. Khôi phục upstream vì `/health/ready` hiện 502.
2. Sửa health-check giả ở Nginx.
3. Ngắt feedback loop reconnect.
4. Lazy-load hai tầng tab.
5. Thêm single-flight cho `loadAllForHome`, dashboard, streak và adherence.
6. Không fallback adherence khi dashboard lỗi auth/rate-limit/server.
7. Xác định tầng phát 429 qua log.
8. Sửa forwarded IP và thứ tự authentication/rate limiter.

### 1–3 ngày – P1

1. Shared `ApiClient`/repository.
2. Retry có jitter, retry budget và `Retry-After`.
3. Redis cache + invalidation.
4. Batch Home bootstrap hoặc dùng dashboard thay adherence.
5. Tối ưu N+1 dashboard và full-history streak query.
6. Structured logging và dashboard metrics.

### Sau khi ổn định – P2

1. Load test các tình huống cold start, token hết hạn, 500, 502 và 429.
2. Canary release.
3. Điều chỉnh limit dựa trên traffic thật.
4. Chỉ nâng Lightsail hoặc thêm AWS WAF sau khi có số liệu CPU/burst/DB chứng minh cần thiết.

## 8. Tiêu chí nghiệm thu

- Cold start Home không khởi tạo request của tab Discover/Meal Plan/Office/Gymer/History/Profile.
- Một URL GET chỉ có một in-flight request cho mỗi user.
- Trong TTL 30 giây, dashboard/streak/adherence không gọi lại nếu không có mutation hoặc force refresh.
- Một 500 không thể được một 401/429 song song biến thành sự kiện reconnect.
- Token refresh chỉ có một request; refresh thất bại dừng toàn bộ replay authenticated.
- 429 không được gọi lại trước `Retry-After`.
- External `/health/ready` phản ánh đúng trạng thái ASP.NET upstream.
- Rate-limit partition log hiển thị đúng user ID hoặc client IP thật, không phải IP Nginx/Cloudflare.
- Load test không xuất hiện request tăng theo cấp số nhân khi backend trả lỗi.
- Với tải mục tiêu, 429/5xx dưới ngưỡng SLO đã thống nhất và CPU Lightsail không cạn burst kéo dài.

## 9. Tài liệu chính thức tham chiếu

- AWS – Retry with backoff:  
  https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- AWS Well-Architected – Control and limit retries:  
  https://docs.aws.amazon.com/wellarchitected/2023-04-10/framework/rel_mitigate_interaction_failure_limit_retries.html
- AWS WAF – Rate-based aggregation keys và forwarded IP:  
  https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based-aggregation-options.html
- AWS Lightsail – CPU và burst capacity metrics:  
  https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-viewing-instance-health-metrics.html
- Microsoft – ASP.NET Core rate limiting và `Retry-After`:  
  https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit
- Microsoft – Forwarded headers qua proxy/load balancer:  
  https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer
- Cloudflare – Khôi phục visitor IP tại Nginx:  
  https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/
- Cloudflare – `CF-Connecting-IP`:  
  https://developers.cloudflare.com/fundamentals/reference/http-headers/

## 10. Kết luận

Nguyên nhân có xác suất cao nhất không phải một `useEffect` đơn lẻ hay giới hạn AWS quá thấp. Đây là tổ hợp:

1. Eager-loading nhiều màn hình.
2. Không deduplicate request.
3. Retry/fallback tăng số lần gọi khi lỗi.
4. Feedback loop reconnect.
5. Rate limiter đang partition theo proxy IP.
6. Endpoint backend tốn DB và thiếu cache.
7. Health-check ngoài báo xanh giả.

Thứ tự đúng là **chặn loop → lazy-load/dedup → sửa IP/rate partition → cache/tối ưu query → đo tải → mới cân nhắc tăng hạ tầng**.
