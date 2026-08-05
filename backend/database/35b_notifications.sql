-- =============================================================================
-- MenuGreen Seed Data - Table: notifications
-- Sequence Number: 35b
-- Phase 8: merged from 35_notifications.sql + 58_notification_action_url.sql
-- (Must run after 35a_campaigns.sql for FK constraint on CampaignId.)
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Title" character varying(200) NULL,
    "Body" character varying(1000) NULL,
    "Type" character varying(100) NULL,
    "ActionUrl" character varying(500) NULL,
    "IsRead" boolean NOT NULL DEFAULT false,
    "CreatedAt" timestamp with time zone NOT NULL,
    "ScheduledAt" timestamp with time zone NULL,
    "SentAt" timestamp with time zone NULL,
    "ReadAt" timestamp with time zone NULL,
    "CampaignId" uuid NULL,
    "ClickedAt" timestamp with time zone NULL,
    "ActionCompletedAt" timestamp with time zone NULL,
    "IsDismissed" boolean NOT NULL DEFAULT false,
    "DismissedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_notifications" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_notifications_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_notifications_campaigns_CampaignId"
        FOREIGN KEY ("CampaignId") REFERENCES campaigns ("Id") ON DELETE SET NULL
);

-- ============================================================
-- Phase 1-7 seed: Reminder notifications per user (existing)
-- ============================================================
INSERT INTO notifications (
    "Id", "UserId", "Title", "Body", "Type",
    "IsRead", "CreatedAt", "ScheduledAt", "SentAt", "ReadAt",
    "ActionUrl"
)
VALUES
-- bbbbbbbb (demo@menugreen.app, Free)
('95928080-6408-4adf-84de-1d23029e7c38', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('3ebbc27a-46cc-4e11-b3bf-df782b2aa329', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- cccccccc (free@menugreen.app, Free)
('51c7b2f0-6011-46a0-9abc-e52b183c3f05', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('18598911-2096-4ea5-a79d-cc6e5ce7141e', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- dddddddd
('b4ec9ee4-a64f-4949-b9fe-09cdbc8aaf95', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('5925de1d-dfe4-47f4-b2bd-d11d79ab676b', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- eeeeeeee
('ca7d4918-75c4-4f0c-bfc8-d1f160575094', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('ba3a8a24-5b8a-4ea3-9151-f73ea84f4119', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- ffffffff (gymer@menugreen.app, Gymer)
('56c7ba5b-e3b9-43d9-a7a4-f650a5ae8110', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('d83f5ca9-d60e-455b-bee4-e15bf778debb', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 885810e8
('589cb3c8-2ba1-4a5d-af32-52d493ac7c4b', '885810e8-168f-4608-a72e-e23a20dfd258', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('a5d13fcb-7a61-44ea-9b8e-c3063737b568', '885810e8-168f-4608-a72e-e23a20dfd258', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 48069bd5
('2ba4a0af-4e8d-4cdd-b804-74be91f9b885', '48069bd5-f29a-417d-bdeb-c00797968aca', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('263f369d-4601-4b53-828e-84e4cb59fb82', '48069bd5-f29a-417d-bdeb-c00797968aca', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 9afb13a5
('c3f968ed-6a54-470b-bf76-396fd755a9db', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('0cb889a8-6d69-4c5e-9de1-4818c7300a05', '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 081b4669
('a0b6b137-5632-461e-b7b5-e3a8df2666dc', '081b4669-b97f-4e75-b089-4c8de0151653', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('36a43dec-790c-4d68-b6cd-d6aabb897231', '081b4669-b97f-4e75-b089-4c8de0151653', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 586209d0
('b7e34712-b822-4a16-be9d-5aacc070b1a4', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('39ffb556-87cc-4c92-88cd-d57316123416', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- b022ccde
('280b7fad-6dd2-4870-bb4e-75282670843c', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('c69c0b6d-4f60-46f9-bdb1-aaaf0dce5564', 'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 453681f7
('6cd1c54a-8f1f-40b9-9594-058e3fa516f2', '453681f7-f489-47ed-842c-bc3ffd220423', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('01907e6f-51d4-48e1-bbd7-610f3861cbfd', '453681f7-f489-47ed-842c-bc3ffd220423', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 396f9dff
('0f4073d6-1273-446b-a7d6-3393636b4655', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('ee4bfdcc-3047-4bf9-a037-d919aa21cb19', '396f9dff-6c2a-422f-b0cc-8eb451168ed3', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 5dc50160
('9cf0d1f9-6e77-465d-8139-e6f8812a47f2', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('e9101e62-9484-4f9b-878b-85fd489ee64d', '5dc50160-db9e-447a-ba33-9026d8800ab5', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- 212ea8ea
('62de0955-2f9b-47a9-b4de-0ed0114313d1', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'Nhắc nhở bữa ăn 1', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
('f5554745-5d56-44c8-b7d7-a4b4822a9dfe', '212ea8ea-749e-44a1-92d2-636bd617cbc8', 'Nhắc nhở bữa ăn 2', 'Đã đến giờ ghi nhận nhật ký ăn uống cho bữa ăn của bạn rồi!', 'Reminder', true, now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day', NULL),
-- ============================================================
-- Phase 8 seed: Coach <-> Gymer actionable notifications (with ActionUrl)
-- Deep-link format:
--   mealplan:{planId}        -> opens MealPlanDetailScreen
--   coach_weekly_report:{id}  -> opens CoachReportDetailScreen
--   gymer_weekly_report:{id}  -> opens Gymer weekly report screen
--   notification:{id}         -> opens NotificationInboxScreen
-- ============================================================
-- 1. Coach: meal_plan_approved sent to Gymer (ffffffff)
('7a000000-0000-0000-0000-000000000001', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'PT đã gửi lộ trình dinh dưỡng', 'Coach đã duyệt và gửi cho bạn lộ trình ăn uống tuần này. Nhấn để xem chi tiết!', 'meal_plan_approved', false, now() - interval '8 days', NULL, now() - interval '8 days', NULL, 'mealplan:a0000000-0000-0000-0000-000000000002'),
-- 2. Coach: weekly_report_reviewed sent to Gymer (ffffffff)
('7a000000-0000-0000-0000-000000000002', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'PT đã duyệt lộ trình của bạn', 'PT đã xem báo cáo tuần của bạn và gửi lại lộ trình mới. Nhấn để xác nhận!', 'weekly_report_reviewed', false, now() - interval '3 days', NULL, now() - interval '3 days', NULL, 'gymer_weekly_report:d1000000-0000-0000-0000-000000000002'),
-- 3. Coach: pt_route_approval sent to Gymer (ffffffff)
('7a000000-0000-0000-0000-000000000003', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Yêu cầu duyệt lộ trình từ học viên', 'Học viên đã gửi yêu cầu duyệt lộ trình dinh dưỡng. Vui lòng xem và phản hồi.', 'pt_route_approval', false, now() - interval '5 days', NULL, now() - interval '5 days', NULL, 'gymer_weekly_report:d1000000-0000-0000-0000-000000000001'),
-- 4. Coach: coach_personal_program sent to Gymer (ffffffff)
('7a000000-0000-0000-0000-000000000004', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'PT đã tạo chương trình dinh dưỡng cho bạn', 'PT đã lên chương trình ăn uống cá nhân hóa cho bạn. Nhấn để xem và bắt đầu!', 'coach_personal_program', false, now() - interval '2 days', NULL, now() - interval '2 days', NULL, 'notification:7a000000-0000-0000-0000-000000000004'),
-- 5. Reminder for demo user (bbbbbbbb) with explicit ActionUrl=NULL
('7a000000-0000-0000-0000-000000000005', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Nhắc nhở ghi nhận bữa ăn', 'Đã đến giờ ghi nhận nhật ký ăn uống bữa sáng. Đừng bỏ lỡ nhé!', 'Reminder', true, now() - interval '1 day', NULL, now() - interval '1 day', now() - interval '1 day', NULL)
ON CONFLICT DO NOTHING;

COMMIT;
