# Firebase FCM Handoff Guide

Date: 2026-07-20

## Muc tieu

Ban khong can giu account Firebase de tiep tuc code. Ban co the dua code nay cho ban cua ban, roi ban do cam Firebase project cua ho vao.

Code hien tai da ho tro:

- Google login qua Firebase ID token
- Dang ky FCM token len backend
- Gui push notification tu backend qua Firebase Admin
- Upload avatar len Firebase Storage

## Ban cua ban can cung cap gi

### Mobile Flutter

1. `google-services.json` cho Android
2. Neu dung Google login backend verify token:
   - `Web client ID` cua Firebase project

### Backend .NET

1. File service account JSON cua Firebase Admin
2. Path toi file do trong config hoac env

## Cho nao can cam vao

### 1. Android app

Dat file vao:

`frontend/android/app/google-services.json`

### 2. Backend Firebase Admin

Dat file service account vao:

`backend/MenuGreen.API/<ten-file>.json`

Config mot trong hai cach:

#### Cach A: appsettings.Development.json

```json
"Firebase": {
  "CredentialPath": "ten-file-service-account.json"
}
```

#### Cach B: Environment variable

```powershell
$env:FIREBASE_CREDENTIAL_PATH="D:\\path\\to\\service-account.json"
```

Code backend da doc ca:

- `Firebase:CredentialPath`
- `FIREBASE_CREDENTIAL_PATH`

### 3. Google login Web client ID

Code Flutter da ho tro override bang `dart-define`.

Chay app:

```powershell
flutter run --dart-define=FIREBASE_GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

Neu khong set, app se dung fallback client id hien tai trong code. Khi ban cua ban doi sang Firebase project khac, nen set lai gia tri nay theo project cua ho.

## Quy trinh test nhanh

### Mobile

1. Cai `google-services.json`
2. Chay app
3. Dang nhap Google
4. Sau login, app dang ky FCM token len backend

### Backend

1. Dat service account JSON
2. Chay API
3. Goi `POST /api/Fcm/send` sau khi user da co device token

## Dau hieu da cau hinh dung

### Google login

Neu backend da nap Firebase Admin dung, loi se khong con la:

- `Google sign-in is not configured on the server.`

Ma neu token test sai, se ra kieu:

- `Invalid or expired Google sign-in token.`

Dieu nay co nghia la credential da load duoc.

### FCM

Neu mobile da lay duoc token va goi backend dang ky thanh cong:

- bang `DeviceTokens` se co ban ghi moi
- endpoint `POST /api/Fcm/send` co the gui push ve user

## Luu y quan trong

### 1. Firebase Storage rules

File hien tai:

`firebase/storage.rules`

Dang qua long cho production. Can siet lai truoc khi release.

### 2. iOS

Neu ban cua ban muon chay iPhone, can them:

- `GoogleService-Info.plist`
- `flutterfire configure`

### 3. Web

Firebase web chua duoc cau hinh day du.

## Files lien quan trong code

- `backend/MenuGreen.API/Program.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/FcmService.cs`
- `frontend/lib/core/services/push_notification_service.dart`
- `frontend/lib/core/services/fcm_repository.dart`
- `frontend/lib/core/services/firebase_google_auth_service.dart`
- `frontend/lib/core/services/firebase_runtime_config.dart`

## Ket luan

Co the code truoc, dua cho ban cua ban cam Firebase project vao sau.

Ban khong can tu dang nhap Firebase Console de viet tiep logic app, mien la:

- mobile dung file `google-services.json` cua dung project
- backend dung dung service account JSON
- Google web client id duoc set dung bang `--dart-define`
