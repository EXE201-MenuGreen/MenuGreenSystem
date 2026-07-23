# 🎯 Play Store Submission Checklist - MenuGreen

**Created:** 2026-07-09  
**Target:** Google Play Store (CH Play)  
**Package Name:** `com.menugreen.app`  
**Current Version:** 1.0.0+1

---

## 📋 Mục lục

1. [ ] Phase 1: Chuẩn bị Tài Khoản
2. [ ] Phase 2: Android Configuration
3. [ ] Phase 3: Chuẩn bị Assets
4. [ ] Phase 4: Build & Signing
5. [ ] Phase 5: Google Play Console Setup
6. [ ] Phase 6: Upload & Review
7. [ ] Phase 7: Post-Launch

---

## ✅ Phase 1: Chuẩn Bị Tài Khoản

| #   | Task                                | Status | Notes |
| --- | ----------------------------------- | ------ | ----- |
| 1.1 | Tạo tài khoản Google Play Developer | ⬜     |       |
| 1.2 | Thanh toán phí $25                  | ⬜     |       |
| 1.3 | Xác minh danh tính Developer        | ⬜     |       |
| 1.4 | Đăng nhập Play Console thành công   | ⬜     |       |

### Actions:

```bash
# Truy cập: https://play.google.com/console
# Thanh toán phí đăng ký $25 (một lần)
```

---

## ✅ Phase 2: Android Configuration

| #   | Task                                       | Status | Notes                            |
| --- | ------------------------------------------ | ------ | -------------------------------- |
| 2.1 | Đổi package name thành `com.menugreen.app` | ⬜     | Hiện tại: `com.example.frontend` |
| 2.2 | Cập nhật `build.gradle.kts`                | ⬜     | namespace + applicationId        |
| 2.3 | Cập nhật `AndroidManifest.xml`             | ⬜     | package attribute                |
| 2.4 | Di chuyển/đổi package MainActivity.kt      | ⬜     | Path: `com/menugreen/app/`       |
| 2.5 | Cập nhật `google-services.json`            | ⬜     | Package phải match               |
| 2.6 | Kiểm tra minSdkVersion                     | ⬜     | Tối thiểu 21 (Android 5.0)       |
| 2.7 | Enable ProGuard/R8                         | ⬜     |                                  |

### Files cần sửa:

#### `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.menugreen.app"  // Đổi từ "com.example.frontend"

    defaultConfig {
        applicationId = "com.menugreen.app"  // Đổi từ "com.example.frontend"
    }
}
```

#### `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.menugreen.app">
```

#### Di chuyển file Kotlin

```bash
# Tạo thư mục mới
mkdir -p android/app/src/main/kotlin/com/menugreen/app

# Di chuyển và cập nhật nội dung file
mv android/app/src/main/kotlin/com/example/frontend/MainActivity.kt \
   android/app/src/main/kotlin/com/menugreen/app/

# Cập nhật package trong file:
# package com.menugreen.app
```

---

## ✅ Phase 3: Chuẩn Bị Assets

| #   | Task                     | Status | Size      | Notes              |
| --- | ------------------------ | ------ | --------- | ------------------ |
| 3.1 | App Icon                 | ⬜     | 512x512   | PNG, không alpha   |
| 3.2 | App Icon (adaptive)      | ⬜     | 1024x1024 | PNG cho Play Store |
| 3.3 | Feature Graphic          | ⬜     | 1024x500  | PNG/JPG            |
| 3.4 | Screenshots Phone (6.7") | ⬜     | 1440x2560 | 2-8 images         |
| 3.5 | Screenshots Phone (5.5") | ⬜     | 1080x1920 | Tùy chọn           |
| 3.6 | Screenshots Tablet       | ⬜     | 2048x2560 | Tùy chọn           |
| 3.7 | App Logo Vector          | ⬜     | 512x512   | SVG tốt hơn        |

### App Icon Sizes cho Android:

```
mipmap-mdpi    → 48x48
mipmap-hdpi    → 72x72
mipmap-xhdpi   → 96x96
mipmap-xxhdpi  → 144x144
mipmap-xxxhdpi → 192x192
mipmap-anydpi-v26 → adaptive icon
```

### Thư mục icons hiện tại:

```
android/app/src/main/res/
├── mipmap-hdpi/
├── mipmap-mdpi/
├── mipmap-xhdpi/
├── mipmap-xxhdpi/
├── mipmap-xxxhdpi/
└── mipmap-anydpi-v26/
```

### Gợi ý tạo Icon:

- Tool: [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)
- Tool: [App Icon Generator](https://appicon.co/)
- Thiết kế gốc: Figma/Canva

---

## ✅ Phase 4: Build & Signing

| #   | Task                                      | Status | Notes                   |
| --- | ----------------------------------------- | ------ | ----------------------- |
| 4.1 | Tạo Keystore                              | ⬜     | `menugreen_release.jks` |
| 4.2 | Tạo `key.properties`                      | ⬜     | File config signing     |
| 4.3 | Cấu hình signing trong `build.gradle.kts` | ⬜     |                         |
| 4.4 | Build release AAB                         | ⬜     |                         |
| 4.5 | Verify AAB file                           | ⬜     | Kiểm tra signature      |

### 4.1 Tạo Keystore:

```bash
cd frontend

# Tạo keystore
keytool -genkey -v -keystore menugreen_release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias menugreen

# Nhập các thông tin khi được hỏi:
# - Keystore password
# - Key password
# - First and Last Name: MenuGreen Team
# - Organization: MenuGreen
# - City, State, Country
```

### 4.2 Tạo key.properties:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=menugreen
storeFile=menugreen_release.jks
```

### 4.3 Cập nhật build.gradle.kts:

```kotlin
// Thêm vào đầu file
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = file(keystoreProperties['storeFile'])
            storePassword = keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

### 4.4 Build AAB:

```bash
cd frontend

# Clean project
flutter clean
flutter pub get

# Build release bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 4.5 Verify AAB:

```bash
# Kiểm tra thông tin bundle
java -jar ~/.android/build-tools/VERSION/apksigner verify -v build/app/outputs/bundle/release/app-release.aab
```

---

## ✅ Phase 5: Google Play Console Setup

| #   | Task                         | Status | Notes                 |
| --- | ---------------------------- | ------ | --------------------- |
| 5.1 | Tạo App mới                  | ⬜     | All apps → Create app |
| 5.2 | Điền App name                | ⬜     | "MenuGreen"           |
| 5.3 | Chọn App type                | ⬜     | "App"                 |
| 5.4 | Chọn Free/Paid               | ⬜     | "Free"                |
| 5.5 | Declare App access           | ⬜     | All/Conditional/Not   |
| 5.6 | Ads declaration              | ⬜     | Yes/No                |
| 5.7 | Content rating questionnaire | ⬜     | Bắt buộc              |
| 5.8 | Target audience              | ⬜     | Chọn age group        |
| 5.9 | Privacy policy               | ⬜     | URL bắt buộc          |

### 5.1-5.4: Tạo App

```
URL: https://play.google.com/console

1. Go to "All apps"
2. Click "Create app"
3. Fill:
   - App name: MenuGreen
   - Default language: Tiếng Việt (vi)
   - App type: App
   - Free or Paid: Free
4. Create
```

### 5.5: App Access Declaration

```
- Nếu app yêu cầu login → Conditional access
- Default: All functionality available without special access
```

### 5.6: Ads Declaration

```
- App có hiển thị ads không?
- Trả lời: No (nếu không có ads)
```

### 5.7: Content Rating (BẮT BUỘC)

```
1. Go to "Content rating"
2. Click "Continue to questionnaire"
3. Fill:
   - Category: Health & Fitness
   - Answer all questions
4. Submit
```

### 5.8: Target Audience & Experience

```
- Age group: 13+
- Chọn các nhóm phù hợp
```

### 5.9: Privacy Policy

```
Cần tạo Privacy Policy page. Options:

Option 1: Tạo trang static trên website
URL: https://menugreen.food/privacy

Option 2: Sử dụng generator miễn phí
- https://www.termsfeed.com/privacy-policy-generator/
- https://privacypolicies.com/privacy-policy-generator/

Option 3: Firebase Privacy Policy (nếu dùng Firebase)

Template:
---
CHÍNH SÁCH BẢO MẬT
MenuGreen

1. Thông tin thu thập
2. Cách sử dụng thông tin
3. Lưu trữ dữ liệu
4. Quyền của người dùng
5. Liên hệ
---
```

---

## ✅ Phase 6: Store Listing

| #   | Task                   | Status | Char Limit | Content                         |
| --- | ---------------------- | ------ | ---------- | ------------------------------- |
| 6.1 | App name               | ⬜     | 50 chars   | MenuGreen                       |
| 6.2 | Short description      | ⬜     | 80 chars   | Ứng dụng dinh dưỡng cá nhân hóa |
| 6.3 | Full description       | ⬜     | 4000 chars | Chi tiết app                    |
| 6.4 | Upload icon            | ⬜     | 512x512    |                                 |
| 6.5 | Upload feature graphic | ⬜     | 1024x500   |                                 |
| 6.6 | Upload screenshots     | ⬜     | 2-8 each   | Phone + Tablet                  |
| 6.7 | App category           | ⬜     |            | Health & Fitness                |
| 6.8 | Tags                   | ⬜     | 500 chars  | nutrition, diet, health         |

### 6.2 Short Description (Tiếng Việt):

```
Ứng dụng dinh dưỡng cá nhân hóa, giúp bạn ăn uống lành mạnh mỗi ngày.
```

### 6.3 Full Description Template:

```markdown
🍎 MenuGreen - Chuyên gia dinh dưỡng trong túi áo

Bạn không biết hôm nay ăn gì? Bạn muốn cải thiện sức khỏe qua ăn uống?
MenuGreen sẽ giúp bạn!

✨ TÍNH NĂNG NỔI BẬT

📋 Lên thực đơn thông minh

- Gợi ý thực đơn hàng ngày phù hợp với mục tiêu
- Cân bằng dinh dưỡng tự động
- Đa dạng món ăn Việt Nam

🥗 Theo dõi dinh dưỡng

- Đếm calories, protein, carb, fat
- Nhận diện thực phẩm bằng camera
- Theo dõi cân nặng và tiến độ

🎯 Cá nhân hóa

- Phù hợp với chế độ ăn kiêng (giảm cân, tăng cơ, giữ dáng)
- Cân nhắc dị ứng thực phẩm
- Điều chỉnh theo ngân sách

💪 Cho Gym/PT

- Hỗ trợ người tập gym
- Tính macro theo mục tiêu
- Gợi ý bữa ăn pre-workout, post-workout

🔔 Nhắc nhở thông minh

- Không quên bữa ăn
- Uống nước đúng giờ
- Thời gian biểu dinh dưỡng

📱 Dễ sử dụng

- Giao diện tiếng Việt
- Thao tác đơn giản
- Offline support

👥 Phù hợp cho:

- Người muốn giảm cân
- Gymer và người tập thể hình
- Người bệnh cần kiểm soát ăn uống
- Người muốn ăn uống lành mạnh

Tải MenuGreen ngay hôm nay và bắt đầu hành trình sống khỏe!

---

Liên hệ: support@menugreen.food
Website: https://menugreen.food
```

---

## ✅ Phase 7: Upload & Release

| #   | Task                     | Status | Notes             |
| --- | ------------------------ | ------ | ----------------- |
| 7.1 | Tạo Production release   | ⬜     |                   |
| 7.2 | Upload AAB file          | ⬜     |                   |
| 7.3 | Hoàn thành Release notes | ⬜     | VN + EN           |
| 7.4 | Chọn App Signing         | ⬜     | Recommend: Google |
| 7.5 | Submit for review        | ⬜     |                   |
| 7.6 | Đợi review               | ⬜     | 1-7 ngày          |

### 7.1-7.2: Tạo Release

```
1. Go to "Production"
2. Click "Create release"
3. Upload .aab file
4. Hoặc kéo thả file
```

### 7.3: Release Notes

```
Vietnamese:
- Phiên bản đầu tiên của ứng dụng MenuGreen
- Các tính năng: Lên thực đơn, theo dõi dinh dưỡng, gợi ý cá nhân hóa

English:
- First release of MenuGreen app
- Features: Meal planning, nutrition tracking, personalized recommendations
```

### 7.4: App Signing

```
Options:
1. Google App Signing (RECOMMENDED)
   - Google sẽ quản lý signing key
   - An toàn hơn, không sợ mất key

2. Export and upload a key
   - Bạn tự quản lý key
   - Rủi ro mất key cao hơn

→ Chọn: "Let Google create and manage my app signing key"
```

### 7.5-7.6: Submit

```
1. Click "Save"
2. Click "Review release"
3. Confirm all checks passed
4. Click "Start release to Production"
5. Confirm
```

---

## ✅ Phase 8: Post-Launch

| #   | Task                            | Status | Notes              |
| --- | ------------------------------- | ------ | ------------------ |
| 8.1 | Kiểm tra app trên Store         | ⬜     | Sau khi approved   |
| 8.2 | Test download từ Play Store     | ⬜     |                    |
| 8.3 | Setup Crashlytics/Bug reporting | ⬜     | Firebase           |
| 8.4 | Setup Analytics                 | ⬜     | Firebase Analytics |
| 8.5 | Monitor reviews                 | ⬜     |                    |
| 8.6 | Chuẩn bị update tiếp theo       | ⬜     |                    |

---

## 🐛 Common Issues & Fixes

| Issue                  | Solution                                                                 |
| ---------------------- | ------------------------------------------------------------------------ |
| App crash on launch    | Test kỹ, fix bugs trước upload                                           |
| Violates policy        | Đọc kỹ [Policy](https://play.google.com/about/developer-content-policy/) |
| Missing privacy policy | Thêm URL vào Store listing                                               |
| Wrong package name     | Đổi lại trong build.gradle.kts                                           |
| Version conflict       | Tăng versionCode trước mỗi release                                       |
| Review takes too long  | Lần đầu 3-7 ngày, lần sau 1-2 ngày                                       |

---

## 📞 Resources

| Resource          | URL                                                      |
| ----------------- | -------------------------------------------------------- |
| Play Console      | https://play.google.com/console                          |
| Developer Policy  | https://play.google.com/about/developer-content-policy/  |
| App Signing       | https://developer.android.com/studio/publish/app-signing |
| Play Core Library | https://developer.android.com/guide/playcore             |

---

## 📝 Notes & Decisions

<!-- Điền thông tin khi hoàn thành -->

| Field              | Value         |
| ------------------ | ------------- |
| Play Console Email |               |
| App Signing by     | Google / Self |
| Keystore Location  |               |
| Privacy Policy URL |               |
| Initial Version    | 1.0.0         |
| Review Date        |               |
| Approved Date      |               |
| Published Date     |               |

---

**Last Updated:** 2026-07-09  
**Status:** Draft - Ready to execute
