-- =============================================================================
-- MenuGreen Seed Data - Table: micro_learning_cards
-- Sequence Number: 49
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS micro_learning_cards CASCADE;

CREATE TABLE micro_learning_cards (
    "Id" uuid NOT NULL,
    "Title" character varying(255) NOT NULL,
    "Summary" text NOT NULL,
    "Category" character varying(100) NOT NULL,
    "Tips" text NULL,
    "ImageUrl" character varying(500) NULL,
    "QuizQuestion" text NULL,
    "QuizOptions" text NULL,
    "CorrectOptionIndex" integer NULL,
    "PointsReward" integer NOT NULL DEFAULT 10,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_micro_learning_cards" PRIMARY KEY ("Id")
);

-- Seed Data for micro_learning_cards
INSERT INTO micro_learning_cards ("Id", "Title", "Summary", "Category", "Tips", "ImageUrl", "QuizQuestion", "QuizOptions", "CorrectOptionIndex", "PointsReward", "IsActive", "CreatedAt")
VALUES
('e1000000-0000-0000-0000-000000000001', 'Hiểu đúng về Protein', 'Protein là khối xây dựng cơ bắp, hỗ trợ trao đổi chất và duy trì cảm giác no lâu. Người trưởng thành cần nạp tối thiểu 0.8g protein trên mỗi kg thể trọng.', 'Protein', 'Ăn ức gà, trứng gà để bổ sung đạm tinh khiết|Kết hợp đạm thực vật từ các loại hạt', 'https://example.com/images/protein.jpg', 'Lượng protein khuyến nghị tối thiểu cho người ít vận động là bao nhiêu?', '0.5g/kg|0.8g/kg|1.5g/kg|2.0g/kg', 1, 15, true, now()),
('e1000000-0000-0000-0000-000000000002', 'Cảnh giác với Muối ẩn', 'Muối có nhiều trong thực phẩm chế biến sẵn, giò chả, nước mắm, làm tăng nguy cơ cao huyết áp và tích nước cơ thể.', 'Sodium', 'Hạn chế chấm ngập nước mắm|Sử dụng gia vị thảo mộc thay thế muối', 'https://example.com/images/salt.jpg', 'Ăn nhiều muối ẩn gây ra tình trạng gì?', 'Mất ngủ|Tích nước và tăng huyết áp|Giảm cơ bắp|Đau xương khớp', 1, 10, true, now())
ON CONFLICT DO NOTHING;

COMMIT;