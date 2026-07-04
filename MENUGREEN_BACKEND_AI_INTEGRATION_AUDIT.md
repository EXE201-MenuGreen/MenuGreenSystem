# MenuGreenSystem Backend Audit And AI Integration Plan

## 1. Scope

Tai lieu nay tom tat nhung gi da duoc quet trong:

- `D:\EXE\MenuGreenSystem\backend`
- `D:\EXE\MenuGreenSystem\frontend-web`
- doi chieu them voi `D:\EXE\RAG_AI_MenuGreen`

Muc tieu:

1. Hieu backend MenuGreenSystem dang van hanh ra sao.
2. Xac dinh co nen tich hop `RAG_AI_MenuGreen` vao day hay khong.
3. Chon diem tich hop hop ly nhat.
4. Tao mot huong UI tam thoi de admin quan ly va user dung thu AI.

---

## 2. Backend MenuGreenSystem dang hoat dong the nao

### 2.1 Kien truc tong the

He thong dang di theo N-tier ro rang:

- `MenuGreen.API`: lop HTTP API
- `MenuGreen.BusinessLogicLayer`: service, DTO, logic nghiep vu
- `MenuGreen.DataAccessLayer`: EF Core, DbContext, entities, repository

Luong xu ly chinh:

1. Client goi `MenuGreen.API`
2. Controller map request vao service
3. Service doc/ghi PostgreSQL thong qua `ApplicationDbContext`
4. API tra JSON cho mobile/web

### 2.2 Source-of-truth cua business

Backend chinh dang la noi so huu state nghiep vu quan trong:

- user
- profile
- health profile
- allergies
- foods / recipes / ingredients
- meal logs
- meal plans
- recommendation history
- AI conversation history

Dieu nay rat quan trong, vi no cho thay AI runtime khong nen tro thanh backend chinh. Runtime AI chi nen la mot worker phia sau.

### 2.3 Auth, security va van hanh

Backend da co san:

- JWT auth
- role policy `AdminOnly` va `UserOnly`
- refresh token flow
- rate limiting cho auth, otp va AI
- Redis optional, fallback sang in-memory cache
- PostgreSQL qua EF Core

Noi khac, MenuGreenSystem da co day du "khung van hanh" de lam API gateway/business backend cho AI.

---

## 3. Nhung module lien quan truc tiep den AI

### 3.1 Recommendation layer hien tai

Backend da co `RecommendationController` va `RecommendationService`.

Phan nay la recommendation theo rule/database:

- calories
- eco
- lunch
- daily-menu
- schedule
- history
- feedback
- explain
- score

No chua phai conversational AI. No hop voi mobile/business API de tra ve suggestion co cau truc.

### 3.2 Nutrition assistant layer hien tai

Backend da co:

- `NutritionAssistantController`
- `NutritionAssistantService`
- bang `AiConversations`
- bang `AiMessages`
- bang `UserAiProfile`

Day chinh la diem tich hop hop ly nhat de noi `RAG_AI_MenuGreen`.

Ly do:

- da co auth
- da co rate limit rieng cho AI
- da co DB luu lich su chat
- da tach rieng thanh mot service
- khong can sua logic meal plan / nutrition tracking o noi khac

### 3.3 Meal plan va meal log da nam o backend chinh

`MealPlanService` va `NutritionTrackingService` dang quan ly:

- ke hoach bua an
- da an thuc te
- quy doi plan item thanh meal log
- thong ke dinh duong

Nen neu AI muon goi y thong minh, AI phai doc context tu backend nay. AI khong nen tu tuong tac truc tiep voi mobile nhu source-of-truth.

---

## 4. Danh gia tich hop `D:\EXE\RAG_AI_MenuGreen`

### 4.1 Ket luan ngan

Co the tich hop, va huong hop ly nhat la:

`mobile/web -> MenuGreenSystem backend -> NutritionAssistantService -> RAG_AI_MenuGreen worker`

Khong nen de mobile goi thang vao `RAG_AI_MenuGreen` neu muc tieu la van hanh lau dai.

### 4.2 Vi sao huong nay hop ly

Neu MenuGreenSystem dung lam gateway/business backend:

- auth chi quan ly o 1 noi
- mobile khong can biet contract worker AI
- business state van nam o 1 noi
- de log, de rate limit, de doi worker ve sau
- co the thay `RAG_AI_MenuGreen` bang worker khac ma mobile gan nhu khong doi

### 4.3 Van de phat hien luc doi chieu contract

Truoc khi sua, `NutritionAssistantService` dang gui payload theo contract cu, dai loai:

- `conversationId`
- `userMessage`
- `context`

Trong khi `RAG_AI_MenuGreen` runtime hien tai can:

- `message`
- `user_id`
- `thread_id`
- `request_id`
- `conversation_history`

Day la mismatch that su. Neu khong sua, tich hop se rat de loi logic hoac loi ngat ngam.

### 4.4 Nhung gi da duoc can chinh trong dot nay

Da cap nhat backend de:

- bridge sang dung contract cua `RAG_AI_MenuGreen`
- gui `conversation_history`
- gui `user_id` va `thread_id`
- them endpoint lay lich su conversation cho user
- them endpoint health/overview cho admin

Noi cach khac, MenuGreenSystem gio da co mot lop bridge dung vai tro "business wrapper" cho AI runtime.

---

## 5. Kien truc tich hop duoc de xuat

### 5.1 Luong chuan

```text
Mobile App / Frontend Web
        |
        v
MenuGreenSystem API
        |
        v
NutritionAssistantService
        |
        v
RAG_AI_MenuGreen (/worker/chat)
        |
        v
Response quay lai MenuGreenSystem
        |
        v
Luu AiMessages / AiConversations / tra JSON cho client
```

### 5.2 Vai tro tung he thong

`MenuGreenSystem`:

- auth
- role
- rate limiting
- DB source-of-truth
- meal state
- profile/allergy/goal context
- log va observability

`RAG_AI_MenuGreen`:

- intent + conversational AI
- hybrid routing ONNX / fallback / Gemini neu can
- query understanding
- response generation

### 5.3 Khuyen nghi cho mobile project lon

Neu mobile project lon dang dung chung DB va dung chung API, thi huong tot nhat la:

- mobile goi `MenuGreenSystem`
- `MenuGreenSystem` moi goi AI runtime

Khong nen:

- mobile goi truc tiep runtime AI
- de runtime AI tro thanh source-of-truth cua meal logs hay meal plans

Ly do:

- kho giu auth
- kho sync business state
- kho audit
- kho doi contract sau nay

---

## 6. UI tam thoi da them trong `frontend-web`

### 6.1 Admin UI

Da them route:

- `/dashboard/ai-assistant`

Muc dich:

- xem worker health
- xem worker URL dang cau hinh
- xem tong AI profiles / conversations / messages
- xem recent conversations
- xac nhan MenuGreenSystem dang noi duoc toi worker hay khong

Day la "control center" cho admin va rat hop ly de de doi tich hop sau nay.

### 6.2 User-facing demo UI

Da them route:

- `/ai-coach`

Muc dich:

- login bang tai khoan user
- xem conversation history
- chat thu voi AI
- kiem tra luong user truoc khi day sang mobile

Route nay duoc tach session rieng de khong pha admin login.

### 6.3 Vi sao lam theo kieu "co the go bo"

Ban da noi ro day chi la giao dien tam de test/use. Cach lam hien tai phu hop vi:

- khong sua sau vao auth flow admin cu
- khong can doi mobile app
- co the xoa route neu sau nay khong can
- van dung dung backend that va AI that

---

## 7. Danh gia muc do hop ly cua tich hop AI

### 7.1 Co hop ly khong

Co. Rat hop ly.

### 7.2 Dieu kien de no on dinh khi len team/mobile

Can giu 3 nguyen tac:

1. Business state o MenuGreenSystem.
2. AI runtime chi la worker.
3. Contract giua hai ben phai version ro rang.

### 7.3 Khi nao khong nen lam theo huong nay

Khong nen neu:

- muon de AI worker tu ghi truc tiep business data chinh
- muon mobile bo qua backend chinh
- muon de nhieu app client tu noi truc tiep vao AI runtime bang contract rieng

Luc do he thong se rat nhanh roi vao tinh trang kho debug, kho security va kho maintain.

---

## 8. Khuyen nghi tiep theo

### 8.1 Nen lam ngay

- dua `NutritionAssistant:WorkerUrl` vao env/secret thay vi hard-code
- thong nhat response contract cho mobile
- them logging request_id va thread_id o ca 2 ben
- them timeout/retry policy ro hon neu worker cham

### 8.2 Nen lam tiep sau do

- them API structured response cho meal-plan AI
- them "AI explanation" metadata tra ve kem response
- them admin page feedback/train sample neu muon dong bo sang runtime
- dong bo weather / seasonal / budget signals neu muon recommendation thong minh hon

### 8.3 Khuyen nghi cho deploy

Neu deploy som:

- deploy `MenuGreenSystem` la API public chinh
- deploy `RAG_AI_MenuGreen` la service private/internal neu co the
- chi mo public endpoint cua backend chinh

Day la huong sach va an toan hon so voi expose worker AI truc tiep.

---

## 9. Ket luan cuoi

MenuGreenSystem hien tai da co san mot "khung backend dung chuan" de tro thanh lop trung gian cho AI. `RAG_AI_MenuGreen` co the tich hop tot, nhung vai tro dung cua no la worker conversational AI, khong phai business backend chinh.

Huong tich hop hop ly nhat la:

- giu business va auth o MenuGreenSystem
- goi AI qua `NutritionAssistantService`
- de mobile/backend lon tiep tuc dung API MenuGreenSystem

UI admin va user demo da duoc them theo huong de test nhanh, de quan sat, va co the go bo sau nay ma khong lam vo kien truc chinh.
