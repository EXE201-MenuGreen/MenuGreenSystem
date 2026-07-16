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

-- Seed Data for micro_learning_cards (English)
INSERT INTO micro_learning_cards ("Id", "Title", "Summary", "Category", "Tips", "ImageUrl", "QuizQuestion", "QuizOptions", "CorrectOptionIndex", "PointsReward", "IsActive", "CreatedAt")
VALUES
('e1000000-0000-0000-0000-000000000001', 'How to Increase Protein Without Gaining Fat?', 'If you want to build muscle or support fat loss without consuming excess calories, choosing the right lean protein sources is crucial. Prioritize lean proteins such as chicken breast, fish, egg whites, or plant-based proteins like tofu and legumes instead of fatty red meats like beef and pork.', 'Protein', 'Prefer skinless chicken breast and steamed fish over fried options|Add plant-based proteins to diversify nutrition|Avoid processed red meats such as sausages and bacon', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', 'Which protein source below is lowest in calories and saturated fat?', 'Pork belly|Skinless chicken breast|Well-marbled beef steak|Fried sausages', 1, 10, true, now()),
('e1000000-0000-0000-0000-000000000002', 'Spotting Hidden Sodium in Takeout Food', 'Eating at restaurants or using pre-packaged foods often causes you to consume excessive salt (sodium) without noticing. Hidden sodium is common in pho and hủ tiếu broth, dipping sauces, pickled vegetables, and pre-made marinades designed to enhance flavor.', 'Sodium', 'Avoid finishing all the broth when eating pho or bún at restaurants|Ask for less sauce or request sauce on the side|Read nutrition labels carefully and avoid products exceeding 20% DV of sodium', 'https://images.unsplash.com/photo-1502741126161-b048400d085d', 'Where is hidden sodium most commonly found when eating out?', 'Fresh lettuce|Pho broth and dipping sauces|White rice|Cold filtered water', 1, 10, true, now()),
('e1000000-0000-0000-0000-000000000003', 'Calcium Alternatives for Cow''s Milk Allergy', 'If you are allergic to cow''s milk or lactose intolerant, milk is no longer a safe calcium source. However, you can still get enough calcium from plant-based foods and healthy milk alternatives.', 'Allergy', 'Use calcium-fortified plant milks such as soy or almond milk|Eat more dark leafy greens like kale and spinach|Add small-boned fish such as sardines and mackerel to your diet', 'https://images.unsplash.com/photo-1550583724-b2692b85b150', 'Which plant-based food below is a rich calcium source suitable for people with cow''s milk allergy?', 'French fries|Kale and spinach|Sticky rice|White flour', 1, 10, true, now()),
('e1000000-0000-0000-0000-000000000004', 'Protein Swap Secrets for Seafood Allergy', 'Seafood is a rich source of Omega-3 fatty acids (EPA and DHA) that help protect heart health. If you have a seafood allergy, you need to find healthy fat sources from plants or algae oil as alternatives.', 'Allergy', 'Use algae oil with pure DHA from plants|Add flaxseeds, chia seeds, and walnuts to meals|Cook with rapeseed oil or soybean oil', 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb', 'Which plant-based fat source below is rich in Omega-3 (ALA) and suitable for people with seafood allergy?', 'Pork fat|Chia seeds and flaxseeds|Trans-fat-heavy margarine|Refined coconut oil', 1, 10, true, now()),
('e1000000-0000-0000-0000-000000000005', 'The Science Behind the 8x8 Hydration Rule', 'Water plays an essential role in detoxification, digestion support, and hunger control. The 8x8 rule recommends drinking 8 glasses of water per day, with each glass around 240ml (about 2 liters total), spread evenly instead of drinking large amounts at once.', 'Hydration', 'Drink a glass of warm water right after waking up|Drink water 30 minutes before meals to support digestion and avoid overeating|Carry a personal water bottle as a reminder to stay hydrated consistently', 'https://images.unsplash.com/photo-1548839134-2472e395222f', 'When is the best time to drink water to support digestion and prevent overeating?', 'Immediately after a full meal|30 minutes before a meal|While chewing food|Only when you feel very thirsty', 1, 10, true, now()),
('e1000000-0000-0000-0000-000000000006', '3-minute desk stretch', 'A short mobility break during desk work can reduce neck and shoulder stiffness and helps interrupt prolonged sitting.', 'Office', 'Roll shoulders slowly for 30 seconds|Stand and walk for one minute|Stretch chest and neck without forcing the range', NULL, 'How often should an office worker take a short movement break?', 'Every hour|Once per day|Only after work|Never', 0, 10, true, now()),
('e1000000-0000-0000-0000-000000000007', 'Healthy snacks for the afternoon', 'Choose a snack with fibre or protein to avoid the afternoon energy crash without exceeding your calorie target.', 'Office', 'Choose unsweetened yogurt, fruit, or a small handful of nuts|Avoid sugar-heavy drinks|Prepare snack portions before work', NULL, 'Which is the best office snack choice?', 'Unsweetened yogurt|Sugary soda|Large bag of chips|Candy', 0, 10, true, now()),
('e1000000-0000-0000-0000-000000000008', 'Pack a balanced office lunchbox', 'A lunchbox works best when it combines a measured carbohydrate, lean protein, vegetables and a dish that remains safe during transport.', 'Office', 'Prepare ingredients the night before|Use an insulated lunch bag|Keep vegetables at least half of the box', NULL, 'Which lunchbox component should occupy the largest portion?', 'Vegetables|Fried food|Sugary drink|Sauce', 0, 10, true, now())
ON CONFLICT DO NOTHING;

COMMIT;
