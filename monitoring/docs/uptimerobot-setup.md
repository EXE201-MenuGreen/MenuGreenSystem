# UptimeRobot Setup Guide - MenuGreen

## Overview

UptimeRobot là dịch vụ monitoring miễn phí giúp theo dõi uptime của website/API:
- **Free tier**: 50 monitors
- **Check interval**: 5 phút
- **Notifications**: Email, SMS, Slack, Push, v.v.

---

## Setup Steps

### 1. Đăng ký UptimeRobot

1. Truy cập: https://uptimerobot.com
2. Click "Sign Up Free"
3. Đăng ký với email/password hoặc Google/GitHub account

### 2. Thêm Monitor cho API

1. Sau khi login, click **"+ Add New Monitor"**

2. Điền thông tin:

```
Monitor Type:       HTTP(s)
Friendly Name:      MenuGreen API
URL:                https://your-domain.com/health
Monitoring Interval: 5 minutes
Alert Contacts:     [Chọn email/SMS của bạn]
```

3. Các monitor cần thêm:

| Monitor Name | URL | Type | Interval |
|-------------|-----|------|---------|
| MenuGreen API | `https://your-domain.com/health` | HTTP(s) | 5 min |
| MenuGreen API (alt) | `https://your-domain.com/health/ready` | HTTP(s) | 5 min |
| Grafana | `https://your-domain.com:3000` | HTTP(s) | 15 min |
| Prometheus | `https://your-domain.com:9090` | HTTP(s) | 15 min |

### 3. Cấu hình Alert Contacts

1. Vào **My Settings** → **Alert Contacts**
2. Click **"Add Alert Contact"**
3. Chọn loại notification:

```
Email Notifications:
├─ alert@example.com
└─ admin@example.com

Slack Integration:
├─ #alerts-menugreen channel
└─ Requires: Slack workspace connected

Pushbullet (Optional):
├─ Push to phone
└─ Requires: Pushbullet account

SMS (Premium only):
├─ +84...
└─ Requires: Paid plan
```

### 4. Cấu hình SSL Certificate Check

1. Trong monitor settings, bật:
   - ✅ "SSL Certificate Monitoring"
   - ✅ "Alert when SSL expires in X days"
   - Set: 30 days

---

## Advanced: Webhook Integration

### Kết nối UptimeRobot → Discord/Slack

1. Vào **My Settings** → **Add Alert Contact**
2. Chọn **Webhook**
3. Webhook URL Discord:

```
https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

4. Payload format cho Discord:

```json
{
  "content": "⚠️ **[Alert Type]** - [MonitorFriendlyName] is [AlertType]!\n\n📊 [MonitorURL]\n⏰ [AlertDateTime]"
}
```

5. Payload format cho Slack:

```json
{
  "text": "⚠️ *[Alert Type]* - [MonitorFriendlyName] is [AlertType]!\n\n📊 <[MonitorURL]|View Monitor>\n⏰ [AlertDateTime]"
}
```

---

## Advanced: Prometheus AlertManager Integration

Nếu muốn UptimeRobot alerts đi vào Prometheus AlertManager:

### 1. Tạo UptimeRobot Webhook Endpoint

Thêm endpoint trong API để nhận UptimeRobot webhooks:

```csharp
// In Program.cs or a controller
app.MapPost("/webhooks/uptimerobot", async context =>
{
    using var reader = new StreamReader(context.Request.Body);
    var body = await reader.ReadToEndAsync();
    
    // Log the alert
    _logger.LogWarning("UptimeRobot Alert: {Body}", body);
    
    // Optionally trigger Grafana/AlertManager
    // Call: http://alertmanager:9093/api/v1/alerts
    
    return Results.Ok();
});
```

### 2. Cấu hình UptimeRobot Webhook

Trong UptimeRobot settings:

```
Webhook URL:    https://your-domain.com/webhooks/uptimerobot
POST format:    JSON
```

---

## Monitoring Best Practices

### 1. Multiple Check Locations

Trong monitor settings:
- ✅ Enable "Monitoring from Multiple Locations"
- Chọn 3-5 locations gần users của bạn:
  - Singapore
  - Hong Kong
  - Japan
  - Vietnam (nếu có)

### 2. Responsive Time Monitoring

Thêm HTTP keyword check:
```
Keyword to Monitor: "Healthy"
Keyword Condition:  Contains
Alert when:         Keyword not found
```

### 3. Maintenance Windows

Khi cần maintenance:

1. Click vào monitor → **"Pause"**
2. Hoặc set **"Maintenance Window"** trong settings
3. Alerts sẽ không gửi trong thời gian maintenance

### 4. Dashboard Widget

Thêm UptimeRobot widget vào Grafana dashboard:

1. Trong Grafana, add panel
2. Query: UptimeRobot API hoặc
3. Import dashboard: https://grafana.com/grafana/dashboards/10873

---

## Troubleshooting

### Alert không gửi?

1. Kiểm tra **Alert Contacts** đã được link với monitor chưa
2. Kiểm tra spam folder (email)
3. Kiểm tra **"Don't alert during maintenance"** đã tắt chưa

### False positives?

1. Tăng monitoring interval (5 min → 10 min)
2. Thêm retry count (3 retries)
3. Điều chỉnh timeout (30s → 60s)

### SSL check failed?

1. Đảm bảo SSL certificate còn valid
2. Kiểm tra redirect HTTP → HTTPS
3. UptimeRobot có thể không follow redirects - dùng URL trực tiếp https://

---

## Cost Summary

| Feature | Free | Paid |
|---------|------|------|
| Monitors | 50 | Unlimited |
| Check interval | 5 min | 1 min |
| Alert contacts | Unlimited | Unlimited |
| SMS alerts | ❌ | ✅ |
| Response time logs | 90 days | Unlimited |
| Cost | $0 | $9/month |

---

## Next Steps

1. ✅ Setup UptimeRobot
2. ✅ Configure alerts
3. ✅ Test alert delivery
4. ⏳ Setup Grafana dashboard (done)
5. ⏳ Setup Nginx reverse proxy with auth (next)

---
