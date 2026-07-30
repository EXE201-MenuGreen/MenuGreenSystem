-- =============================================================================
-- Phase 8: Coach <-> Gymer Private Chat
-- Sequence Number: 57
-- Note: MealPlan coach fields (MinCalories/MaxCalories/CoachNotes) are already
-- defined in the CREATE TABLE of 24_meal_plan_headers.sql.
-- Idempotent: safe to run repeatedly.
-- =============================================================================
BEGIN;

-- Create coach_chat_messages table (Phase 8: Coach <-> Gymer chat).
CREATE TABLE IF NOT EXISTS coach_chat_messages (
    "Id" uuid NOT NULL,
    "SenderId" uuid NOT NULL,
    "ReceiverId" uuid NOT NULL,
    "Content" character varying(2000) NOT NULL,
    "SentAt" timestamp with time zone NOT NULL,
    "ReadAt" timestamp with time zone NULL,
    CONSTRAINT "PK_coach_chat_messages" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_coach_chat_messages_users_SenderId"
        FOREIGN KEY ("SenderId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_coach_chat_messages_users_ReceiverId"
        FOREIGN KEY ("ReceiverId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_coach_chat_messages_SenderId_ReceiverId_SentAt"
    ON coach_chat_messages ("SenderId", "ReceiverId", "SentAt");

CREATE INDEX IF NOT EXISTS "IX_coach_chat_messages_ReceiverId_ReadAt"
    ON coach_chat_messages ("ReceiverId", "ReadAt");

-- Seed conversation between Coach (77777777) and Gymer (ffffffff).
-- Coach sends plan instructions, Gymer confirms, Coach gives follow-up advice.

-- 1. Coach -> Gymer: Intro message after connecting.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000001',
    '77777777-7777-7777-7777-777777777777',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Chào bạn! Mình là PT của bạn. Để mình lên lộ trình dinh dưỡng phù hợp với mục tiêu tập gym của bạn nhé. Bạn đang tập gym mấy ngày/tuần?',
    now() - interval '9 days',
    now() - interval '9 days'
)
ON CONFLICT DO NOTHING;

-- 2. Gymer -> Coach: Confirm training schedule.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000002',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '77777777-7777-7777-7777-777777777777',
    'Dạ chào PT! Mình tập 5 ngày/tuần, tập trung tăng cơ và giảm mỡ. Calo hiện tại khoảng 2000. Mình ăn khá nhiều cơm.',
    now() - interval '9 days',
    now() - interval '9 days'
)
ON CONFLICT DO NOTHING;

-- 3. Coach -> Gymer: Plan summary sent.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000003',
    '77777777-7777-7777-7777-777777777777',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Okê! Mình sẽ để calo khoảng 1850, protein 140g/ngày. Bạn giảm cơm bữa tối xuống 1 chén thay vì 2 chén nhé. Đạm bữa sáng thêm lòng trắng trứng hoặc ức gà. Mình đã gửi lộ trình trong app rồi đó.',
    now() - interval '8 days',
    now() - interval '8 days'
)
ON CONFLICT DO NOTHING;

-- 4. Gymer -> Coach: Confirmed plan received.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000004',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '77777777-7777-7777-7777-777777777777',
    'Dạ em đã nhận lộ trình rồi! Calo 1850 có giảm nhiều không so với 2000 ban đầu? Em sợ không đủ sức tập buổi chiều.',
    now() - interval '8 days',
    now() - interval '8 days'
)
ON CONFLICT DO NOTHING;

-- 5. Coach -> Gymer: Reassurance + adjustment tip.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000005',
    '77777777-7777-7777-7777-777777777777',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Không sao đâu! Bạn bổ sung thêm 1 chén cơm bữa trưa nếu thấy yếu. Carb là nguồn năng lượng chính cho buổi tập. Quan trọng là giữ protein đủ 140g, ưu tiên ức gà, cá hồi, trứng. Nếu cần mình sẽ điều chỉnh lên 1900 sau tuần đầu.',
    now() - interval '7 days',
    now() - interval '7 days'
)
ON CONFLICT DO NOTHING;

-- 6. Gymer -> Coach: Weekly report submission.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000006',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '77777777-7777-7777-7777-777777777777',
    'Dạ em đã gửi báo cáo tuần! Mình cảm thấy khỏe hơn, bữa sáng đủ no đến trưa. Nhưng bữa tối hơi thiếu vì ăn sớm lúc 18h.',
    now() - interval '3 days',
    now() - interval '3 days'
)
ON CONFLICT DO NOTHING;

-- 7. Coach -> Gymer: Review feedback + follow-up plan.
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000007',
    '77777777-7777-7777-7777-777777777777',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Tốt lắm! Mình đã xem báo cáo. Đạm bạn đạt 138g, gần đạt mục tiêu. Carb tuần này hơi thấp — bổ sung thêm khoai lang hoặc gạo lứt bữa tối nhé. Mình sẽ gửi lộ trình tuần mới cho bạn trong app.',
    now() - interval '2 days',
    now() - interval '2 days'
)
ON CONFLICT DO NOTHING;

-- 8. Coach -> Gymer: New PersonalProgram sent (unread).
INSERT INTO coach_chat_messages (
    "Id", "SenderId", "ReceiverId", "Content", "SentAt", "ReadAt"
)
VALUES
(
    'c1000000-0000-0000-0000-000000000008',
    '77777777-7777-7777-7777-777777777777',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Lộ trình tuần mới đã được gửi trong app! Focus tuần này: tăng protein bữa sáng, giảm đồ chiên, bổ sung rau xanh bữa trưa. Nhấn xem trong app và nhấn "Áp dụng" nhé!',
    now() - interval '1 day',
    NULL
)
ON CONFLICT DO NOTHING;

COMMIT;
