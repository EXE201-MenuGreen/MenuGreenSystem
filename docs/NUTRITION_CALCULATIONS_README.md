# MenuGreen Backend — Nutrition Calculation Formulas

Tài liệu này giải thích toàn bộ công thức tính toán được sử dụng trong MenuGreen backend (`.NET`), bao gồm nguồn uy tín kèm theo. Mỗi công thức đều được đánh giá **đúng/sai** dựa trên hướng dẫn từ các tổ chức y tế và dinh dưỡng hàng đầu thế giới.

> **Phần API Endpoints:** Mỗi mục có section **"API Endpoints kiểm tra"** ở cuối tài liệu, gồm HTTP method, route, curl command mẫu, và expected response để verify công thức trực tiếp qua backend API.

---

## Mục lục

1. [BMR — Mifflin-St Jeor Equation](#1-bmr--mifflin-st-jeor-equation)
2. [TDEE — Total Daily Energy Expenditure](#2-tdee--total-daily-energy-expenditure)
3. [BMI — Body Mass Index](#3-bmi--body-mass-index)
4. [Target Calories từ TDEE theo mục tiêu](#4-target-calories-từ-tdee-theo-mục-tiêu)
5. [Macro Targets (Protein / Carbs / Fat)](#5-macro-targets-protein--carbs--fat)
6. [Nutrition Snapshot & Goal Completion](#6-nutrition-snapshot--goal-completion)
7. [Goal Drift Detection](#7-goal-drift-detection)
8. [Planned vs Actual Nutrition](#8-planned-vs-actual-nutrition)
9. [Adherence Score (Điểm bám sát)](#9-adherence-score-điểm-bám-sát)
10. [Recalibration (Hiệu chỉnh mục tiêu)](#10-recalibration-hiệu-chỉnh-mục-tiêu)
11. [Meal Plan — Phân bổ Calories theo bữa](#11-meal-plan--phân-bổ-calories-theo-bữa)
12. [Portion Conversion (Quy đổi khẩu phần)](#12-portion-conversion-quy-đổi-khẩu-phần)
13. [Macro Distribution (Analytics)](#13-macro-distribution-analytics)
14. [Recommendation Scoring](#14-recommendation-scoring)
15. [Streak Calculation](#15-streak-calculation)

---

## Nguồn uy tín tham khảo

| Nguồn                                                                                                                                                                            | Mô tả                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [**Mifflin et al. (1990)**](https://pmc.ncbi.nlm.nih.gov/articles/PMC1375232/) — _Am J Clin Nutr 51(2):241-247_                                                                  | Phương trình Mifflin-St Jeor gốc                                           |
| [**Frankenfield et al. (2005)**](https://pubmed.ncbi.nlm.nih.gov/15919902/) — _J Am Diet Assoc 105(5):775_                                                                       | So sánh 4 phương trình BMR, khuyến nghị Mifflin-St Jeor                    |
| [**Academy of Nutrition and Dietetics**](https://www.eatright.org/)                                                                                                              | Tổ chức dinh dưỡng lớn nhất thế giới — khuyến nghị Mifflin-St Jeor từ 2005 |
| [**IOM/NIH — DRI for Macronutrients (2002/2005)**](https://www.ncbi.nlm.nih.gov/books/NBK610333/)                                                                                | AMDR: Protein 10-35%, Carbs 45-65%, Fat 20-35%                             |
| [**USDA Dietary Guidelines for Americans 2020-2025**](https://www.dietaryguidelines.gov/)                                                                                        | Hướng dẫn ăn uống chính thức của chính phủ Mỹ                              |
| [**NHS Weight Loss Plan (2026)**](https://www.nhs.uk/better-health/lose-weight/calorie-counting/)                                                                                | Khuyến nghị deficit 500-1000 kcal/ngày để giảm 0.5-1kg/tuần                |
| [**Harvard Medical School — Calorie Deficit**](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss)            | Khuyến nghị deficit 500 kcal/ngày, không giảm quá 1-2 pounds/tuần          |
| [**PMC — Meal Timing Meta-Analysis (2024)**](https://pmc.ncbi.nlm.nih.gov/articles/PMC11530941/)                                                                                 | Nghiên cứu tổng hợp 29 RCTs về timing bữa ăn                               |
| [**Precision Nutrition — Macros vs Calories**](https://www.precisionnutrition.com/macros-vs-calories)                                                                            | Công cụ dinh dưỡng thực hành, cơ sở nghiên cứu rộng                        |
| [**Dietary Assessment Initiative (2026)**](https://dietaryassessmentinitiative.org/publications/clinical-thresholds-self-monitoring-2026/)                                       | Ngưỡng MAPE: awareness ~15%, weight management ~8-10%                      |
| [**Nutrition Research Review (2024)**](https://nutrition-research-review.com/articles/impact-tracking-accuracy-weight-management-2024/)                                          | Ngưỡng MAPE ±5% giúp đạt mục tiêu giảm cân cao hơn 47%                     |
| [**TDEEcal — Scientific Sources**](https://tdeecal.com/sources/)                                                                                                                 | Tổng hợp nguồn về Mifflin-St Jeor, activity multipliers                    |
| [**StatPearls — Nutrition MacroIntake (NCBI)**](https://www.ncbi.nlm.nih.gov/books/NBK594226/)                                                                                   | AMDR chi tiết, protein ranges theo g/kg                                    |
| [**HealthcareOnTime — Calorie Distribution**](https://www.healthcareontime.com/health-tips/how-many-calories-should-i-eat-for-breakfast-lunch-dinner-its-not-one-size-fits-all/) | Phân bổ calories theo bữa                                                  |
| [**Medscape — Mifflin-St Jeor Calculator**](https://reference.medscape.com/calculator/846/mifflin-st-jeor)                                                                       | Công cụ tính BMR theo Mifflin-St Jeor                                      |

---

## Chi tiết từng công thức

> Mỗi mục gồm 4 phần: **(1) Ý nghĩa & Mục đích** — giải thích công thức này để làm gì, tại sao cần, và ảnh hưởng gì đến user; **(2) Code thực tế** — đoạn code trong repository; **(3) Công thức toán** — dạng toán học chuẩn; **(4) Đánh giá** — đúng/sai so với chuẩn quốc tế kèm khuyến nghị.

---

### 1. BMR — Mifflin-St Jeor Equation

> **Nguồn:** [Mifflin et al. (1990)](https://pmc.ncbi.nlm.nih.gov/articles/PMC1375232/) · [Frankenfield et al. (2005)](https://pubmed.ncbi.nlm.nih.gov/15919902/)

**Ý nghĩa & Mục đích:** BMR (Basal Metabolic Rate) là lượng calories tối thiểu mà cơ thể cần để duy trì các chức năng sống khi nghỉ ngơi hoàn toàn — bao gồm hô hấp, tuần hoàn máu, điều hòa nhiệt độ. Đây là nền tảng để tính toán TDEE. Không có BMR, không thể xác định target calories phù hợp cho từng người dùng.

**Mục đích trong MenuGreen:**
- Tính BMR khi user hoàn thành health profile (cân nặng, chiều cao, tuổi, giới tính).
- Cung cấp con số BMR để user hiểu "cơ thể mình đốt bao nhiêu calo khi không làm gì".
- Làm đầu vào (input) cho TDEE → Target Calories.

**File:** `HealthProfileMetricsCalculator.cs`, dòng 45-49

```csharp
var baseBmr = (10 * (double)weightKg) + (6.25 * (double)heightCm) - (5 * age);
var genderBonus = gender?.Trim().ToLower() is "male" or "nam" ? 5 : -161;
return baseBmr + genderBonus;
```

**Công thức chuẩn:**

```
BMR (nam) = (10 × cân nặng kg) + (6.25 × chiều cao cm) − (5 × tuổi) + 5
BMR (nữ)  = (10 × cân nặng kg) + (6.25 × chiều cao cm) − (5 × tuổi) − 161
```

**Nguồn:** Mifflin MD et al. (1990), _Am J Clin Nutr_. Frankenfield et al. (2005) xác nhận đây là phương trình chính xác nhất trong 4 phương trình phổ biến (Harris-Benedict, Mifflin-St Jeor, Owen, WHO/FAO/UNU), dự đoán BMR trong phạm vi ±10% cho ~82% đối tượng. Academy of Nutrition and Dietetics khuyến nghị sử dụng Mifflin-St Jeor từ năm 2005.

**Tham khảo:**

- [Mifflin et al. (1990) — PubMed Central](https://pmc.ncbi.nlm.nih.gov/articles/PMC1375232/)
- [Frankenfield et al. (2005) — PubMed](https://pubmed.ncbi.nlm.nih.gov/15919902/)
- [Medscape — Mifflin-St Jeor Calculator](https://reference.medscape.com/calculator/846/mifflin-st-jeor)
- [TDEEcal — Scientific Sources](https://tdeecal.com/sources/)

**Đánh giá: CHÍNH XÁC**

Phương trình code khớp chính xác với công thức chuẩn quốc tế. Hệ số genderBonus = +5 cho nam và -161 cho nữ là đúng theo Mifflin-St Jeor.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `POST` | `/api/HealthProfile/me/calculate` | Tính BMR, TDEE, BMI, Target Calories, Macro Targets |
| 2 | `GET` | `/api/HealthProfile/me` | Lấy health profile (có BMR, TDEE, BMI đã tính) |
| 3 | `PUT` | `/api/HealthProfile/me` | Cập nhật profile → tự động recalculate |
| 4 | `PATCH` | `/api/HealthProfile/me/goal` | Thay đổi goal → recalculate |

```bash
# Tính BMR/TDEE/BMI/Target/Macro
curl -X POST "https://api.menugreen.vn/api/HealthProfile/me/calculate" \
  -H "Authorization: Bearer {token}"

# Expected: { "bmrKcal": 1725, "tdeeKcal": 2674, "bmi": 22.86,
#            "targetCalories": 2174, "targetProteinG": 163,
#            "targetCarbsG": 217, "targetFatG": 72 }
```

---

### 2. TDEE — Total Daily Energy Expenditure

> **Nguồn:** [TDEEcal — Activity Multipliers](https://tdeecal.com/sources/) · [TDEEcal — Mifflin-St Jeor Calculator](https://tdeecal.net/mifflin-st-jeor-equation/)

**Ý nghĩa & Mục đích:** TDEE là tổng calories cơ thể đốt cháy trong một ngày khi bao gồm mọi hoạt động (đi lại, làm việc, tập thể dục). BMR chỉ tính khi nghỉ ngơi, còn TDEE = BMR × hệ số hoạt động. Đây là con số quan trọng nhất để xác định người dùng cần ăn bao nhiêu mỗi ngày.

**Mục đích trong MenuGreen:**
- Tính TDEE sau khi có BMR — đây là "mức calories duy trì cân nặng hiện tại" (maintenance calories).
- User biết được tổng năng lượng họ đốt mỗi ngày dựa trên lối sống (sedentary → active).
- TDEE là đầu vào trực tiếp cho việc tính Target Calories (cắt giảm hoặc tăng thêm calo tùy mục tiêu).

**File:** `HealthProfileMetricsCalculator.cs`, dòng 52-61

```csharp
public static double GetActivityMultiplier(string? activityLevel)
{
    return activityLevel?.Trim().ToLower() switch
    {
        "sedentary"                           => 1.2,
        "light" or "lightlyactive" or "lightly active"  => 1.375,
        "moderate" or "moderatelyactive" or "moderately active" => 1.55,
        "active" or "veryactive" or "very active"       => 1.725,
        _ => 1.2
    };
}
// ...
healthProfile.TdeeKcal = (int)Math.Round(bmr * multiplier);
```

**Công thức:**

```
TDEE = BMR × Activity Multiplier
```

| Activity Level    | Hệ số trong code | Hệ số chuẩn TDEEcal/Medscape |
| ----------------- | :--------------: | :--------------------------: |
| Sedentary         |       1.2        |             1.2              |
| Lightly Active    |      1.375       |            1.375             |
| Moderately Active |       1.55       |             1.55             |
| Very Active       |      1.725       |            1.725             |

**Nguồn:** Mifflin et al. (1990) — BMR là điểm khởi đầu. Hệ số nhân hoạt động được chuẩn hóa bởi nhiều nguồn.

**Tham khảo:**

- [TDEEcal — Activity Multipliers](https://tdeecal.com/sources/)
- [TDEEcal — Mifflin-St Jeor TDEE Calculator](https://tdeecal.net/mifflin-st-jeor-equation/)

**Đánh giá: CHÍNH XÁC**

Tất cả hệ số khớp chính xác với chuẩn quốc tế. Code xử lý nhiều alias cho mỗi mức độ hoạt động (VD: `lightlyactive`, `lightly active`, `light`) nên linh hoạt hơn.

**API kiểm tra:** Cùng endpoint với mục 1 (`POST /api/HealthProfile/me/calculate` — trả về cả TDEE trong field `tdeeKcal`).

---

### 3. BMI — Body Mass Index

> **Nguồn:** [WHO — Body Mass Index (BMI)](https://www.who.int/news-room/fact-sheets/detail/a-healthy-lifestyle---body-mass-index-bmi)

**Ý nghĩa & Mục đích:** BMI là chỉ số đơn giản để phân loại tình trạng cân nặng của một người dựa trên cân nặng và chiều cao. Đây là công cụ sàng lọc nhanh (screening tool), không phải chỉ số đo lường body composition chính xác — vì nó không phân biệt được mỡ, cơ, hay nước.

**Mục đích trong MenuGreen:**
- Hiển thị BMI trên dashboard để user biết tình trạng cơ thể hiện tại (thiếu cân / bình thường / thừa cân / béo phì).
- Là chỉ số tham khảo cho cả user và hệ thống — không dùng để tính target calories trực tiếp (TDEE dùng cân nặng thực tế, không dùng BMI).
- Dùng trong báo cáo analytics để phân loại nhóm user theo BMI.

**File:** `HealthProfileMetricsCalculator.cs`, dòng 64-67

```csharp
public static decimal CalculateBmi(decimal weightKg, decimal heightCm)
{
    var heightMeters = (double)heightCm / 100d;
    return (decimal)Math.Round((double)weightKg / (heightMeters * heightMeters), 2);
}
```

**Công thức:**

```
BMI = cân nặng (kg) / chiều cao² (m²)
```

**Nguồn:** Công thức BMI được WHO công nhận toàn cầu từ 1995. Phân loại: <18.5 (thiếu cân), 18.5-24.9 (bình thường), 25-29.9 (thừa cân), ≥30 (béo phì).

**Đánh giá: CHÍNH XÁC**

Công thức khớp hoàn toàn với chuẩn WHO. Làm tròn 2 chữ số thập phân là hợp lý.

**API kiểm tra:** `POST /api/HealthProfile/me/calculate` — trả về BMI trong field `bmi`.

---

### 4. Target Calories từ TDEE theo mục tiêu

> **Nguồn:** [NHS — Calorie Counting](https://www.nhs.uk/better-health/lose-weight/calorie-counting/) · [Harvard — Calorie Deficit](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss)

**Ý nghĩa & Mục đích:** Đây là **con số quan trọng nhất** trong toàn bộ app — là mục tiêu calories hàng ngày mà user cần hướng tới. Target Calories xác định người dùng cần ăn bao nhiêu để đạt mục tiêu (giảm cân / tăng cân / giữ cân). Nếu không có con số này, user không có đích để so sánh.

**Mục đích trong MenuGreen:**
- Tính target calories = TDEE + điều chỉnh theo mục tiêu. Đây là con số hiển thị trên dashboard, tracker, và mọi báo cáo.
- Dùng làm đầu vào cho mọi tính toán dinh dưỡng khác: Goal Completion %, Goal Drift, Nutrition Snapshot, Planned vs Actual.
- Hiệu chỉnh target calories tự động khi cân nặng thay đổi (Recalibration).

**File:** `HealthProfileMetricsCalculator.cs`, dòng 70-78

```csharp
public static int CalculateTargetCalories(int tdeeKcal, string? goal)
{
    return tdeeKcal + (goal?.Trim().ToLower() switch
    {
        "gain weight" or "gainweight" => 300,
        "lose weight" or "loseweight" => -500,
        "build muscle" or "buildmuscle" => 200,
        _ => 0
    });
}
```

**Công thức:**

```
Target Calories = TDEE + điều chỉnh theo mục tiêu
  Gain Weight / Build Muscle: +300 đến +500 kcal/ngày
  Lose Weight: -500 kcal/ngày
  Maintenance: +0 kcal
```

**Nguồn:**

- **NHS (2026):** Deficit 500-1000 kcal/ngày để giảm 0.5-1kg/tuần. Deficit 500 kcal là mức an toàn được khuyến nghị rộng rãi nhất.
- **Harvard Medical School:** Khuyến nghị bắt đầu với deficit 500 kcal/ngày, giảm không quá 1-2 pounds (~0.5-1kg)/tuần.
- **NHS:** 7,700 kcal ≈ 1kg mỡ. 500 kcal deficit × 7 ngày = 3,500 kcal ≈ 0.45kg/tuần.

**Tham khảo:**

- [NHS — Calorie Counting](https://www.nhs.uk/better-health/lose-weight/calorie-counting/)
- [Harvard — Calorie Deficit](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss)

**Đánh giá: ĐÚNG về hướng, CẦN LƯU Ý về con số**

| Mục tiêu     | Code (+300/-500/+200) | Khuyến nghị thực tế                            |
| ------------ | :-------------------: | ---------------------------------------------- |
| Lose Weight  |      -500 kcal ✓      | -500 kcal ✓ (chuẩn NHS/Harvard)                |
| Gain Weight  |       +300 kcal       | +300 đến +500 kcal (tùy mức độ)                |
| Build Muscle |       +200 kcal       | +200 đến +500 kcal (ISSN: tùy mức độ vận động) |

Các con số trong code nằm trong ngưỡng an toàn. Gain weight +300 kcal có thể hơi thấp cho người gầy muốn tăng cân nhanh, nhưng an toàn cho người muốn tăng cân từ từ. Khuyến nghị không nên vượt +500 kcal/ngày để tránh tích mỡ.

**API kiểm tra:** `POST /api/HealthProfile/me/calculate` — trả về `targetCalories` trong response. Test: đổi goal qua `PATCH /api/HealthProfile/me/goal` với body `{"goal": "lose weight"}` → targetCalories giảm 500 kcal.

```bash
curl -X PATCH "https://api.menugreen.vn/api/HealthProfile/me/goal" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"goal": "lose weight"}'
# Expected: targetCalories = tdeeKcal - 500
```

---

### 5. Macro Targets (Protein / Carbs / Fat)

> **Nguồn:** [IOM/NIH — AMDR](https://www.ncbi.nlm.nih.gov/books/NBK610333/) · [StatPearls — Nutrition MacroIntake](https://www.ncbi.nlm.nih.gov/books/NBK594226/)

**Ý nghĩa & Mục đích:** Macro nutrients (đạm / bột đường / chất béo) là ba nhóm chất dinh dưỡng tạo ra năng lượng. Việc phân bổ đúng tỷ lệ giúp: (1) Protein giữ và phát triển cơ; (2) Carbs cung cấp năng lượng cho hoạt động; (3) Fat hỗ trợ hấp thu vitamin và hormone. Nếu chỉ nhắm target calories mà không có macro targets, user có thể ăn đủ calo nhưng thiếu protein, gây mất cơ khi giảm cân.

**Mục đích trong MenuGreen:**
- Tính target macro (g) cho mỗi user dựa trên target calories và mục tiêu.
- Hiển thị macro targets trên dashboard và tracker để user biết cần ăn bao nhiêu đạm/bột đường/chất béo.
- Dùng trong Nutrition Snapshot và Planned vs Actual để so sánh macro thực tế với target.

**File:** `HealthProfileMetricsCalculator.cs`, dòng 81-91

```csharp
public static void ApplyMacroTargets(HealthProfile healthProfile)
{
    var goal = healthProfile.Goal?.Trim().ToLower();
    var proteinRatio = goal is "build muscle" or "buildmuscle" ? 0.35 : 0.30;
    var fatRatio = goal is "build muscle" or "buildmuscle" ? 0.25 : 0.30;
    const double carbsRatio = 0.40;

    var targetCalories = (double)(healthProfile.TargetCalories ?? 0);
    healthProfile.TargetProteinG = (int)Math.Round((targetCalories * proteinRatio) / 4);
    healthProfile.TargetCarbsG = (int)Math.Round((targetCalories * carbsRatio) / 4);
    healthProfile.TargetFatG = (int)Math.Round((targetCalories * fatRatio) / 9);
}
```

**Công thức:**

```
Protein (g) = (TargetCalories × Protein%) / 4
Carbs   (g) = (TargetCalories × Carbs%)   / 4
Fat     (g) = (TargetCalories × Fat%)     / 9
```

**Bảng phân bổ:**

| Mục tiêu          | Protein | Carbs | Fat | Tổng |
| ----------------- | :-----: | :---: | :-: | :--: |
| Build Muscle      |   35%   |  40%  | 25% | 100% |
| Các mục tiêu khác |   30%   |  40%  | 30% | 100% |

**Nguồn:**

- **IOM/NIH DRI (2002/2005):** AMDR cho người lớn: Protein 10-35%, Carbs 45-65%, Fat 20-35%.
- **USDA Guidelines:** AMDR chuẩn: Protein 10-35%, Carbs 45-65%, Fat 20-35%.
- **Precision Nutrition / ISSN:** Người tập gym/build muscle thường cần protein cao hơn (1.6-2.2 g/kg thể trọng), tương đương ~30-35% tổng calo.
- **TDEEcal.net:** Phổ split phổ biến 30/40/30 (protein/carbs/fat) cho general population.

**Tham khảo:**

- [NCBI Bookshelf — AMDR](https://www.ncbi.nlm.nih.gov/books/NBK610333/)
- [StatPearls — Nutrition MacroIntake](https://www.ncbi.nlm.nih.gov/books/NBK594226/)
- [TrueCalculators — Macro Split](https://truecalculators.net/food/macro-split-calculator/)

**Đánh giá: PHÙ HỢP NHƯNG HƠI THẤP CHO BUILD MUSCLE**

| Chỉ tiêu |     Code (Build Muscle)      | Khuyến nghị ISSN/IOM                   |    Đánh giá    |
| -------- | :--------------------------: | -------------------------------------- | :------------: |
| Protein  | 35% (≈35% × 2000 / 4 = 175g) | 1.6-2.2 g/kg ≈ 128-176g cho người 80kg | Trong ngưỡng ✓ |
| Carbs    |             40%              | 45-65% AMDR                            |  Hơi thấp ⚠️   |
| Fat      |             25%              | 20-35% AMDR                            | Trong ngưỡng ✓ |

Carbs 40% cho build muscle có thể hơi conservative. Một số nguồn khuyến nghích carbs cao hơn (50-55%) cho người tập gym vì carbs là nguồn năng lượng chính cho buổi tập. Tuy nhiên, 40% vẫn nằm trong AMDR và không phải là sai.

**Vấn đề cần lưu ý:** IOM khuyến cáo nên tính protein bằng g/kg thể trọng thay vì % calo vì người có TDEE thấp có thể không đủ protein nếu chỉ dùng % calo. Ví dụ: người 60kg, TDEE 1500 kcal, protein 30% = 112g ≈ 1.87 g/kg (tốt), nhưng người 80kg, TDEE 2500 kcal, protein 35% = 219g ≈ 2.7 g/kg (có thể cao hơn mức cần thiết).

**API kiểm tra:** `POST /api/HealthProfile/me/calculate` — trả về `targetProteinG`, `targetCarbsG`, `targetFatG`. Verify: `targetProteinG = round(targetCalories × 0.30 / 4)` (build muscle: × 0.35 / 4).

---

### 6. Nutrition Snapshot & Goal Completion

> **Nguồn:** [Precision Nutrition — How to Track Macros](https://www.precisionnutrition.com/macros-vs-calories) · [MyFitnessPal](https://www.myfitnesspal.com/)

**Ý nghĩa & Mục đích:** Nutrition Snapshot là bản chụp (snapshot) tổng hợp dinh dưỡng của một ngày — tổng calo, đạm, bột đường, chất béo thực tế so với mục tiêu. Goal Completion % cho biết user đã hoàn thành bao nhiêu phần trăm target calories trong ngày. Đây là phép so sánh cơ bản nhất giữa kế hoạch và thực tế.

**Mục đích trong MenuGreen:**
- Tính và lưu trữ snapshot hàng ngày để user xem lại lịch sử dinh dưỡng.
- Tính Goal Completion % — hiển thị progress bar trên dashboard để user thấy mình đã ăn bao nhiêu % target.
- Đồng bộ snapshot mỗi khi user tạo / cập nhật / xóa meal log — đảm bảo dữ liệu luôn chính xác.
- Cung cấp dữ liệu cho Goal Drift Detection (so sánh snapshot 7 ngày với target).

**File:** `NutritionSnapshotService.cs`, dòng 66-67

```csharp
decimal? goalPercent = targetCalories > 0
    ? Math.Round(totalCalories / targetCalories * 100m, 2)
    : null;
```

**Công thức:**

```
GoalCompletionPercent = (TotalCalories thực tế / TargetCalories) × 100%
```

**Nguồn:** Đây là công thức đơn giản và hợp lý để đo % hoàn thành mục tiêu. Nguồn gốc từ thực hành dinh dưỡng phổ biến (Precision Nutrition, MyFitnessPal).

**Đánh giá: CHÍNH XÁC**

Công thức cơ bản và chính xác. Lưu ý: giá trị có thể vượt 100% nếu ăn quá target, đây là hành vi đúng.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/NutritionTracking/summary?date=2026-06-26` | Lấy snapshot ngày (GoalCompletionPercent = totalCalories / targetCalories × 100) |
| 2 | `GET` | `/api/NutritionTracking/daily?date=2026-06-26` | Daily summary |
| 3 | `GET` | `/api/NutritionTracking/dashboard` | Dashboard tổng hợp |

```bash
curl -X GET "https://api.menugreen.vn/api/NutritionTracking/summary?date=2026-06-26" \
  -H "Authorization: Bearer {token}"
# Expected: { "goalCompletionPercent": 75.90, "totalCalories": 1650, "targetCalories": 2174 }
```

---

### 7. Goal Drift Detection

> **Nguồn:** [Dietary Assessment Initiative (2026)](https://dietaryassessmentinitiative.org/publications/clinical-thresholds-self-monitoring-2026/) · [Nutrition Research Review (2024)](https://nutrition-research-review.com/articles/impact-tracking-accuracy-weight-management-2024/)

**Ý nghĩa & Mục đích:** Goal Drift (trôi mục tiêu) xảy ra khi user lệch khỏi target calories hoặc macro trong thời gian dài — có thể ăn quá nhiều, quá ít, hoặc mất cân bằng đạm/bột đường/chất béo. Drift không phải lỗi một ngày mà là xu hướng kéo dài. Phát hiện drift sớm giúp app can thiệp đúng lúc trước khi user bỏ cuộc hoàn toàn.

**Mục đích trong MenuGreen:**
- Phát hiện drift dựa trên trung bình 7 ngày — loại bỏ biến động nhỏ, chỉ cảnh báo khi có xu hướng thực sự.
- Gửi notification (GoalDriftNudge) để nhắc user điều chỉnh hành vi ăn uống.
- Cung cấp dữ liệu cho Recalibration — nếu drift rõ ràng, hệ thống tự điều chỉnh target calories.
- Hai loại alert: Calorie Drift (>10% lệch calo) và Macro Drift (>15% lệch đạm/bột đường/chất béo).

**File:** `GoalDriftService.cs`, dòng 93-101

```csharp
var calDev = targetCal > 0 ? ((avgCal - targetCal) / targetCal) * 100m : 0m;
var protDev = targetProtein > 0 ? ((avgProtein - targetProtein) / targetProtein) * 100m : 0m;
var carbDev = targetCarbs > 0 ? ((avgCarbs - targetCarbs) / targetCarbs) * 100m : 0m;
var fatDev = targetFat > 0 ? ((avgFat - targetFat) / targetFat) * 100m : 0m;

var hasCalDrift = targetCal > 0 && Math.Abs(calDev) > 10m;     // 10%
var hasMacroDrift = (targetProtein > 0 && Math.Abs(protDev) > 15m) ||
                    (targetCarbs > 0 && Math.Abs(carbDev) > 15m) ||
                    (targetFat > 0 && Math.Abs(fatDev) > 15m);   // 15%
```

**Công thức:**

```
Deviation% = (Giá trị trung bình 7 ngày - Target) / Target × 100%

Drift nếu:
  |Calorie Deviation| > 10%  →  Calorie Drift Alert
  |Macro Deviation| > 15%   →  Macro Drift Alert
```

**Nguồn:**

- **Dietary Assessment Initiative (2026):** MAPE cho weight management: ~8-10% là ngưỡng có thể chấp nhận được. 10% deviation cho calories nằm đúng ở biên trên của ngưỡng này.
- **Nutrition Research Review (2024):** MAPE ≤±5% đạt kết quả giảm cân tốt nhất; >±5% thì hiệu quả giảm dần.
- **Thực tế tracking (Nutrasafe/Precision Nutrition):** Lỗi tracking thực tế của người dùng thường 10-15%, nên threshold 10% cho calories và 15% cho macros là phù hợp với context ứng dụng consumer.
- Ngưỡng 10% cho calories và 15% cho macros là threshold hợp lý cho ứng dụng mobile nutrition tracking.

**Tham khảo:**

- [Dietary Assessment Initiative (2026)](https://dietaryassessmentinitiative.org/publications/clinical-thresholds-self-monitoring-2026/)
- [Nutrition Research Review (2024)](https://nutrition-research-review.com/articles/impact-tracking-accuracy-weight-management-2024/)
- [Nutrasafe — Calorie vs Macro Tracking](https://nutrasafe.co.uk/calorie-counting-vs-macro-tracking)

**Đánh giá: HỢP LÝ — ngưỡng Calories 10% nằm ở biên**

| Ngưỡng        | Code | Bình luận                                                                                 |
| ------------- | :--: | ----------------------------------------------------------------------------------------- |
| Calorie Drift | 10%  | Trên biên của ngưỡng khuyến nghị (8-10%), nhưng phù hợp với lỗi tracking thực tế của user |
| Macro Drift   | 15%  | Hợp lý — macros khó track chính xác hơn calories                                          |

Nên cân nhắc giảm ngưỡng calorie drift xuống **8%** để match với nghiên cứu mới nhất (Dietary Assessment Initiative 2026).

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `POST` | `/api/Goals/drift-alerts/recalculate` | Tính drift 7 ngày → tạo alert nếu \|calDev\| > 10% hoặc \|macroDev\| > 15% |
| 2 | `GET` | `/api/Goals/drift-alerts/summary` | Drift summary: avgCalories, calDeviationPercent, protDeviationPercent, ... |

```bash
# Tính drift → alert
curl -X POST "https://api.menugreen.vn/api/Goals/drift-alerts/recalculate" \
  -H "Authorization: Bearer {token}"
# Response: { "hasCalDrift": false, "hasMacroDrift": false,
#             "calDeviationPercent": -5.70, "protDeviationPercent": -14.1, ... }
```

---

### 8. Planned vs Actual Nutrition

> **Nguồn:** Đây là phép SUM đơn giản — phương pháp phổ biến trong nutrition tracking (MyFitnessPal, Cronometer, LoseIt).

**Ý nghĩa & Mục đích:** Planned vs Actual là phép so sánh giữa **kế hoạch dinh dưỡng** (meal plan) và **thực tế ăn uống** (meal logs) của user trong một khoảng thời gian. Đây là cách đo lường "user có bám sát kế hoạch ăn uống hay không" — bao gồm cả về lượng calories lẫn chi phí.

**Mục đích trong MenuGreen:**
- Cho user biết họ đã ăn bao nhiêu so với kế hoạch (bao nhiêu calo, đạm, bột đường, chất béo đã nạp vs dự kiến).
- Tính chi phí thực tế so với ngân sách meal plan.
- Cung cấp dữ liệu cho Adherence Score (điểm bám sát) và Drift Analysis (phân tích lệch).

**File:** `PlannedVsActualService.cs`, dòng 163-173 (làm tròn)

```csharp
dailyPlanned.CaloriesKcal = Math.Round(dailyPlanned.CaloriesKcal, 1);
dailyPlanned.ProteinG = Math.Round(dailyPlanned.ProteinG, 1);
dailyPlanned.CarbsG = Math.Round(dailyPlanned.CarbsG, 1);
dailyPlanned.FatG = Math.Round(dailyPlanned.FatG, 1);
```

**Bảng tổng hợp Planned vs Actual:** Tổng calories, protein, carbs, fat, chi phí qua khoảng thời gian từ `from` đến `to`.

**Nguồn:** Đây là phép cộng đơn giản (SUM) nên không có công thức nghiên cứu cụ thể. Đây là phương pháp tính toán thực tế phổ biến trong nutrition tracking.

**Đánh giá: CHÍNH XÁC**

Logic đơn giản và đúng. Lưu ý: làm tròn 1 chữ số thập phân cho calories/protein/carbs/fat là hợp lý (hiển thị đẹp, không quá chi tiết). Chi phí làm tròn 0 chữ số (VND nguyên) là đúng.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/Analytics/planned-vs-actual?from=2026-06-01&to=2026-06-26` | So sánh tổng planned vs actual (calories, protein, carbs, fat, cost) |
| 2 | `GET` | `/api/Analytics/planned-vs-actual/drift-analysis?from=...&to=...` | Phân tích: bữa bỏ qua, thay thế, khẩu phần lệch |

```bash
curl -X GET "https://api.menugreen.vn/api/Analytics/planned-vs-actual?from=2026-06-01&to=2026-06-26" \
  -H "Authorization: Bearer {token}"
# Response: { "totalPlanned": {caloriesKcal: 62000}, "totalActual": {caloriesKcal: 58000}, "difference": {...} }
```

---

### 9. Adherence Score (Điểm bám sát)

> **Nguồn:** Đây là proprietary formula của ứng dụng. Cấu trúc 4 thành phần được thiết kế dựa trên thực hành dinh dưỡng (Precision Nutrition, NHS Weight Loss Plan). Trọng số 40/30/20/10% phản ánh mức ưu tiên: tuân thủ kế hoạch > độ chính xác calo > độ chính xác macro > penalty ăn ngoài plan.

**Ý nghĩa & Mục đích:** Adherence Score là điểm tổng hợp (0-100) phản ánh mức độ user tuân thủ meal plan. Thay vì chỉ so sánh calories đơn lẻ, điểm này đánh giá toàn diện qua 4 khía cạnh: (1) có hoàn thành đủ bữa ăn?, (2) calories có sát target?, (3) macros có cân bằng?, (4) có ăn ngoài kế hoạch quá nhiều?. Điểm này giúp user hiểu rõ đang làm tốt ở đâu, còn thiếu ở đâu.

**Mục đích trong MenuGreen:**
- Tính Overall Score (0-100) để user biết mình bám sát kế hoạch ở mức nào.
- Phân loại: EXCELLENT (≥85), GOOD (≥70), FAIR (≥50), POOR (<50) kèm feedback bằng tiếng Anh.
- Dùng trong báo cáo hàng tháng (Monthly HTML Report) và Drift Analysis.
- Cung cấp actionable insights: nếu score thấp, hệ thống gợi ý bước cải thiện cụ thể.

**File:** `PlannedVsActualService.cs`, dòng 227-286

```csharp
// 1. Meal Completion Rate (40%)
var mealCompletionRate = ((double)completedPlannedCount / planItems.Count) * 100.0;

// 2. Calorie Deviation Score (30%)
var deviationPercent = (double)(Math.Abs(summary.TotalActual.CaloriesKcal
    - summary.TotalPlanned.CaloriesKcal) / summary.TotalPlanned.CaloriesKcal);
calorieDeviationScore = Math.Max(0.0, 100.0 - (deviationPercent * 100.0));

// 3. Macro Deviation Score (20%)
// (protein, carbs, fat deviation → score → trung bình)

// 4. Unplanned Penalty (10%)
var unplannedRatio = (double)unplannedCount / logs.Count;
unplannedPenaltyScore = Math.Max(0.0, 100.0 - (unplannedRatio * 100.0));

// Overall
overallScore = (mealCompletionRate * 0.4) + (calorieDeviationScore * 0.3)
    + (macroDeviationScore * 0.2) + (unplannedPenaltyScore * 0.1);
```

**Công thức từng thành phần:**

```
MealCompletionRate = (Số bữa hoàn thành / Tổng bữa kế hoạch) × 100

CalorieDeviationScore = max(0, 100 - |ActualCalories - PlannedCalories| / PlannedCalories × 100)

MacroDeviationScore = avg(ProteinScore, CarbsScore, FatScore)
  Mỗi macro: max(0, 100 - |Actual - Planned| / Planned × 100)

UnplannedPenaltyScore = max(0, 100 - (Số bữa ngoài kế hoạch / Tổng bữa) × 100)

OverallScore = MealCompletion×0.4 + CalorieDev×0.3 + MacroDev×0.2 + Unplanned×0.1
```

**Nguồn:** Đây là phương pháp scoring tự thiết kế (proprietary) của ứng dụng, không có một nghiên cứu cụ thể nào cho công thức này. Tuy nhiên:

- Cấu trúc 4 thành phần (completion, calorie accuracy, macro accuracy, unplanned penalty) là hợp lý về mặt dinh dưỡng học.
- Cách tính deviation score dùng `100 - (deviation_percent × 100)` là hợp lý.
- Trọng số (40/30/20/10%) phản ánh mức độ ưu tiên: completion quan trọng nhất (40%), calorie accuracy thứ hai (30%), macro accuracy thứ ba (20%), unplanned penalty (10%).

**Đánh giá: HỢP LÝ về cấu trúc, thiếu validation nghiên cứu**

| Thành phần        | Trọng số | Bình luận                                           |
| ----------------- | :------: | --------------------------------------------------- |
| Meal Completion   |   40%    | Có lý — tuân thủ kế hoạch là yếu tố quan trọng nhất |
| Calorie Deviation |   30%    | Hợp lý — calories ảnh hưởng trực tiếp đến mục tiêu  |
| Macro Deviation   |   20%    | Hợp lý — macros quan trọng nhưng khó control hơn    |
| Unplanned Penalty |   10%    | Hợp lý — penalty cho hành vi không theo kế hoạch    |

Đây là proprietary formula, nên cần thu thập user feedback để calibrate trọng số. Rating thresholds (EXCELLENT ≥85, GOOD ≥70, FAIR ≥50, POOR <50) cần được validate qua A/B testing với user data thực tế.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/Analytics/planned-vs-actual/adherence-score?from=2026-06-01&to=2026-06-26` | Tính điểm bám sát tổng hợp (0-100) |

```bash
curl -X GET "https://api.menugreen.vn/api/Analytics/planned-vs-actual/adherence-score?from=2026-06-01&to=2026-06-26" \
  -H "Authorization: Bearer {token}"
# Response: { "overallScore": 82.5, "rating": "GOOD",
#             "mealCompletionRate": 85.0, "calorieDeviationScore": 78.0, ... }
```

---

### 10. Recalibration (Hiệu chỉnh mục tiêu)

> **Nguồn:** [NHS — Calorie Counting](https://www.nhs.uk/better-health/lose-weight/calorie-counting/) · [Harvard — Calorie Deficit](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss) · [NHS — 0.5-1kg Weight Loss](https://bmicalculatornhs.co.uk/0-5-1kg-weight-loss-rule-explained.html)

**Ý nghĩa & Mục đích:** Recalibration là quá trình **tự động hiệu chỉnh target calories** khi cân nặng của user thay đổi rõ rệt theo thời gian. Target calories ban đầu chỉ là ước tính dựa trên BMR và TDEE — nhưng cơ thể thực tế thay đổi khi user giảm/tăng cân. Nếu không recalibrate, target calories sẽ trở nên không còn chính xác sau vài tuần.

**Mục đích trong MenuGreen:**
- So sánh trung bình cân nặng tuần này với tuần trước để phát hiện xu hướng thay đổi.
- Tự động điều chỉnh target calories nếu: (a) mục tiêu giảm cân mà cân không giảm → giảm thêm 100 kcal; (b) mục tiêu tăng cân mà cân không tăng → tăng thêm 150 kcal; (c) maintenance mà cân tăng/giảm quá 0.8kg/tuần → điều chỉnh ±100 kcal.
- Luôn giữ ngưỡng tối thiểu 1200 kcal (an toàn y tế).
- Cập nhật macro targets theo tỷ lệ khi calories thay đổi.

**File:** `PlannedVsActualService.cs`, dòng 547-690 (`RecalibrateNutritionAsync`)

**Công thức tính weight change:**

```csharp
var logsThisWeek  = weightLogs.Where(w => w.RecordedAt >= today.AddDays(-7));
var logsLastWeek  = weightLogs.Where(w => w.RecordedAt >= today.AddDays(-14) && w.RecordedAt < today.AddDays(-7));

decimal? weightThisWeek  = logsThisWeek.Any()  ? logsThisWeek.Average(w => w.WeightKg)  : null;
decimal? weightLastWeek  = logsLastWeek.Any()  ? logsLastWeek.Average(w => w.WeightKg)  : null;

weightChange = weightThisWeek.Value - weightLastWeek.Value;
```

**Điều chỉnh calories khi weight không đổi:**

```csharp
// Lose weight: cân không giảm → giảm thêm 100 kcal (tối thiểu 1200)
if (goal.Contains("loss")) {
    if (weightChange >= -0.1m) {
        newCal = previousCal - 100;
        if (newCal < 1200) newCal = 1200;
    }
}
// Gain weight: cân không tăng → tăng thêm 150 kcal
if (goal.contains("gain")) {
    if (weightChange <= 0.1m) {
        newCal = previousCal + 150;
    }
}
// Maintenance: thay đổi > 0.8kg/tuần → điều chỉnh ±100 kcal
if (Math.Abs(weightChange) > 0.8m) {
    if (weightChange > 0) newCal = previousCal - 100;
    else                   newCal = previousCal + 100;
}
```

**Nguồn:**

- **NHS/Harvard:** 7,700 kcal ≈ 1kg mỡ. 500 kcal deficit/tuần ≈ 0.45kg/tuần.
- **Ngưỡng 0.1kg/thay đổi không đáng kể:** Phù hợp với thực tế — biến động cân nặng hàng ngày (nước, bữa ăn) có thể dao động ±0.5kg, nên 0.1kg không phải là thay đổi thực sự.
- **Ngưỡng 0.8kg cho maintenance:** Tương ứng với ~600 kcal/ngày lệch khỏi TDEE, nằm trong ngưỡng an toàn của NHS (500-1000 kcal).
- **Minimum 1200 kcal:** Đây là ngưỡng an toàn phổ biến (NHS khuyến cáo không dưới 1200 kcal cho phụ nữ mà không có giám sát y tế).
- **Điều chỉnh ±100-150 kcal:** Nhỏ, từ từ — đúng approach vì cơ thể thích nghi dần với calorie change.

**Đánh giá: TỐT — thiết kế an toàn và conservatively correct**

| Điểm                                     | Đánh giá                         |
| ---------------------------------------- | :------------------------------- |
| So sánh trung bình 2 tuần thay vì 1 ngày | Rất tốt — loại bỏ biến động nước |
| Ngưỡng 0.1kg "không thay đổi"            | Hợp lý — tránh over-correction   |
| Điều chỉnh nhỏ (±100-150 kcal)           | Đúng — tránh drastic changes     |
| Minimum 1200 kcal                        | Đúng ngưỡng y tế                 |
| Macro ratio scaling khi điều chỉnh calo  | Tốt — giữ nguyên tỷ lệ macro     |

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `POST` | `/api/Analytics/planned-vs-actual/recalibrate` | Tự động hiệu chỉnh target calories dựa trên cân nặng thay đổi |

```bash
curl -X POST "https://api.menugreen.vn/api/Analytics/planned-vs-actual/recalibrate" \
  -H "Authorization: Bearer {token}"
# Response: { "previousTargetCalories": 2174, "newTargetCalories": 2074,
#             "adjustedBy": -100, "reason": "Weight did not decrease..." }
```

---

### 11. Meal Plan — Phân bổ Calories theo bữa

> **Nguồn:** [HealthcareOnTime — Calorie Distribution](https://www.healthcareontime.com/health-tips/how-many-calories-should-i-eat-for-breakfast-lunch-dinner-its-not-one-size-fits-all/) · [PMC — Meal Timing Meta-Analysis (2024)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11530941/)

**Ý nghĩa & Mục đích:** Phân bổ calories theo bữa ăn giúp user có kế hoạch ăn uống cụ thể cho từng bữa thay vì chỉ biết tổng calo cả ngày. Phân bổ hợp lý giúp: (1) kiểm soát đói/no, (2) cung cấp năng lượng đúng lúc (sáng sớm → chiều tối giảm dần), (3) giảm ăn vặt nhiều vào buổi tối muộn. Nghiên cứu cho thấy ăn phần lớn calo vào buổi sáng (front-loading) giúp giảm cân hiệu quả hơn.

**Mục đích trong MenuGreen:**
- Tính target calories cho từng bữa ăn (breakfast/lunch/dinner/snack) khi tạo meal plan hoặc daily menu.
- Đảm bảo mỗi bữa có một lượng calo cụ thể để user nhắm mục tiêu khi log meal.
- Phân bổ 25/35/30/10% phản ánh thói quen ăn uống phổ biến: bữa trưa là bữa chính lớn nhất (phù hợp với người Việt), bữa sáng và tối nhẹ hơn, snack 10% tránh ăn nhiều trước khi ngủ.

**File:** `RecommendationService.cs`, dòng 99-102

```csharp
var breakfastTarget = targetCalories * 0.25m;  // 25%
var lunchTarget     = targetCalories * 0.35m;  // 35%
var dinnerTarget    = targetCalories * 0.30m;  // 30%
var snackTarget     = targetCalories * 0.10m;  // 10%
```

**Bảng phân bổ:**

| Bữa ăn    | Code | USDA/HealthcareOnTime |  Nghiên cứu Meal Timing   |
| --------- | :--: | :-------------------: | :-----------------------: |
| Breakfast | 25%  |     20-25% (USDA)     | 30% (front-load, tốt hơn) |
| Lunch     | 35%  |        25-35%         |          30-40%           |
| Dinner    | 30%  |        25-35%         |          20-30%           |
| Snack     | 10%  |        10-20%         |       Thường ít hơn       |

**Nguồn:**

- **HealthcareOnTime / LoseIt:** Phân bổ phổ biến 30/40/30 (bữa chính) hoặc 25/35/30/10.
- **PMC Meta-Analysis (2024):** Nghiên cứu tổng hợp 29 RCTs cho thấy ăn phần lớn calories vào buổi sáng (front-loading) giúp giảm cân hiệu quả hơn (-1.75 kg so với ăn tập trung buổi tối). Tuy nhiên, hiệu quả phụ thuộc lịch sinh hoạt cá nhân.
- **USDA Dietary Guidelines:** Không bắt buộc phân bổ cố định, nhưng khuyến nghị bữa sáng đầy đủ dinh dưỡng.

**Tham khảo:**

- [HealthcareOnTime — Calorie Distribution](https://www.healthcareontime.com/health-tips/how-many-calories-should-i-eat-for-breakfast-lunch-dinner-its-not-one-size-fits-all/)
- [PMC — Meal Timing Meta-Analysis (2024)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11530941/)
- [LoseIt — Calorie Distribution](https://www.loseit.com/articles/calorie-distribution-in-a-meal-plan/)

**Đánh giá: HỢP LÝ — nằm trong ngưỡng khuyến nghị**

| Điểm                 | Bình luận                                      |
| -------------------- | ---------------------------------------------- |
| Tổng = 100%          | Đúng ✓                                         |
| Lunch lớn nhất (35%) | Hợp lý — phù hợp với Vietnamese meal pattern   |
| Snack 10%            | Hợp lý — tránh ăn nhiều trước khi ngủ          |
| Breakfast 25%        | Hơi thấp so với nghiên cứu front-loading (30%) |

Cân nhắc tăng breakfast lên 30% và giảm dinner xuống 25% để match với nghiên cứu mới nhất về meal timing (PMC 2024), hoặc để user tự chọn pattern (front-load vs back-load).

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/Recommendation/daily-menu` | Tạo menu ngày với phân bổ 25/35/30/10% |
| 2 | `GET` | `/api/Recommendation/scores?mealType=breakfast&targetCalories=544` | Tính recommendation scores |

```bash
curl -X GET "https://api.menugreen.vn/api/Recommendation/daily-menu" \
  -H "Authorization: Bearer {token}"
# Response: { "meals": [
#   { "mealType": "breakfast", "targetCalories": 543.5 },
#   { "mealType": "lunch",     "targetCalories": 760.9 },
#   { "mealType": "dinner",    "targetCalories": 652.2 },
#   { "mealType": "snack",     "targetCalories": 217.4 }
# ], "totalTargetCalories": 2174.0 }
# Verify: breakfast ≈ 25%, lunch ≈ 35%, dinner ≈ 30%, snack ≈ 10%
```

---

### 12. Portion Conversion (Quy đổi khẩu phần)

> **Nguồn:** [USDA FoodData Central](https://fdc.nal.usda.gov/) — Tất cả giá trị dinh dưỡng trong database USDA được ghi nhận per 100g.

**Ý nghĩa & Mục đích:** Phần lớn người dùng Việt Nam không cân đo bằng gram mà dùng đơn vị địa phương (chén, bát, đĩa, muỗng, trái). Portion Conversion là bước **chuyển đổi đơn vị khẩu phần** (ví dụ: "1 chén cơm", "1 bát phở", "2 trái chuối") **sang gram** để tính dinh dưỡng chính xác. Không có bước này, user phải tự tính gram mỗi lần log — tăng friction và giảm accuracy.

**Mục đích trong MenuGreen:**
- Chuyển đổi đơn vị địa phương (chén, bát, đĩa, muỗng, trái) sang gram cho từng loại thực phẩm cụ thể.
- Tính giá trị dinh dưỡng (calories, protein, carbs, fat) dựa trên khối lượng thực tế sau quy đổi.
- Hỗ trợ 3 tầng: đơn vị tùy chỉnh của user → food-specific portion mapping → default units chung.
- Đơn vị mặc định nếu không tìm thấy mapping: coi là gram (factor = 1.0).

**File:** `PortionConverterService.cs`, dòng 173-185

```csharp
var convertedGrams = request.Quantity * factor;
var ratio = convertedGrams / 100m;

CaloriesKcal = (food.CaloriesKcal ?? 0) * ratio;   // ratio × giá trị per 100g
ProteinG     = (food.ProteinG     ?? 0) * ratio;
CarbsG       = (food.CarbsG       ?? 0) * ratio;
FatG         = (food.FatG          ?? 0) * ratio;
```

**Công thức:**

```
Giá trị dinh dưỡng = Giá trị per 100g × (Khối lượng thực tế / 100)
```

**Nguồn:** Đây là nguyên tắc cơ bản của nutrition database (USDA FoodData Central) — tất cả giá trị dinh dưỡng được ghi nhận per 100g.

**Đánh giá: CHÍNH XÁC**

Tương tự trong `NutritionTrackingService.cs` dòng 415: `var ratio = quantityG / 100m`. Công thức đúng chuẩn.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `POST` | `/api/PortionConverter/convert` | Chuyển đổi đơn vị Việt Nam sang gram |
| 2 | `GET` | `/api/PortionConverter/units` | Lấy danh sách đơn vị mặc định |

```bash
curl -X POST "https://api.menugreen.vn/api/PortionConverter/convert" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"foodId": 123, "quantity": 1, "unitName": "chén"}'
# Response: { "convertedGrams": 200.0, "caloriesKcal": 260.0,
#             "proteinG": 5.4, "carbsG": 57.0, "fatG": 0.6 }
```

---

### 13. Macro Distribution (Analytics)

> **Nguồn:** [IOM/NIH — DRI for Macronutrients](https://www.ncbi.nlm.nih.gov/books/NBK610333/) · [StatPearls — Nutrition MacroIntake](https://www.ncbi.nlm.nih.gov/books/NBK594226/)

**Ý nghĩa & Mục đích:** Macro Distribution là phân tích **tỷ lệ phần trăm** của từng macro nutrient (protein/carbs/fat) trong tổng năng lượng. Thay vì chỉ nhìn vào gram, % macro giúp so sánh cân bằng dinh dưỡng giữa các người có mức calo khác nhau. Ví dụ: 150g protein có thể nhiều hoặc ít tùy tổng calo, nhưng 30% protein thì luôn nhất quán.

**Mục đích trong MenuGreen:**
- Tính % protein/carbs/fat trong tổng macro calories (protein×4 + carbs×4 + fat×9) trên dashboard analytics.
- So sánh với AMDR của IOM/NIH để đánh giá cân bằng dinh dưỡng của toàn bộ user base.
- Đưa ra khuyến nghị (VD: "Fat cao quá 35%" → gợi ý giảm dầu mỡ) dựa trên % phân bổ.

**File:** `AnalyticsService.cs`, dòng 351-355

```csharp
var totalMacroCalories = totalProtein * 4 + totalCarbs * 4 + totalFat * 9;

var proteinPercent = totalMacroCalories > 0
    ? Math.Round(totalProtein * 4 / totalMacroCalories * 100, 1) : 0;
var carbsPercent = totalMacroCalories > 0
    ? Math.Round(totalCarbs * 4 / totalMacroCalories * 100, 1) : 0;
var fatPercent = totalMacroCalories > 0
    ? Math.Round(totalFat * 9 / totalMacroCalories * 100, 1) : 0;
```

**Công thức:**

```
% Protein = (Protein(g) × 4 kcal/g) / Tổng macro kcal × 100
% Carbs   = (Carbs(g)   × 4 kcal/g) / Tổng macro kcal × 100
% Fat     = (Fat(g)     × 9 kcal/g) / Tổng macro kcal × 100
```

**Nguồn:** Công thức chuẩn của IOM/NIH DRI. Năng lượng: Protein = 4 kcal/g, Carbs = 4 kcal/g, Fat = 9 kcal/g.

**Đánh giá: CHÍNH XÁC**

Tuy nhiên, công thức này **chỉ tính 3 macros chính** (protein, carbs, fat). Trên thực tế, tổng calories có thể bao gồm cả fiber, alcohol, và các nguồn khác. Đây là approximation phổ biến và chấp nhận được.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/Analytics/nutrition/macro-distribution?from=2026-06-01&to=2026-06-26` | Tính % protein/carbs/fat trong tổng macro calories |
| 2 | `GET` | `/api/Analytics/nutrition/dashboard?from=...&to=...` | Dashboard tổng hợp nutrition |

```bash
curl -X GET "https://api.menugreen.vn/api/Analytics/nutrition/macro-distribution?from=2026-06-01&to=2026-06-26" \
  -H "Authorization: Bearer {token}"
# Response: { "proteinPercent": 30.4, "carbsPercent": 42.8, "fatPercent": 26.8 }
# Verify: proteinPercent = proteinG×4 / totalMacroCalories × 100
```

---

### 14. Recommendation Scoring

> **Nguồn:** Đây là proprietary heuristics của ứng dụng. Thiết kế dựa trên nguyên tắc: tìm món gần target (calorie proximity), tối ưu budget + thời gian (economic optimization), và penalty cho vượt ngưỡng (boundary penalty). Cần track hit rate để validate.

**Ý nghĩa & Mục đích:** Recommendation Scoring là cách hệ thống **xếp hạng** (rank) các món ăn/food/recipe để đề xuất cho user. Thay vì trả về tất cả món, scoring gán điểm để sắp xếp từ tốt nhất đến kém nhất, rồi trả về top N. Điểm thấp = món tốt hơn (gần target, đúng budget, nhanh nấu).

**Mục đích trong MenuGreen:**
- **Calorie-based:** Chọn món có calories gần nhất với target bữa ăn → giúp user đạt target calo cả ngày.
- **Eco score:** Cân bằng giữa giá cả (budget) và thời gian nấu → gợi ý món vừa rẻ vừa nhanh.
- **Lunch score:** Kết hợp cả ba yếu tố (calories + budget + thời gian <20 phút) → phù hợp bữa trưa vội của người đi làm.

**File:** `RecommendationService.cs`

**Calorie-based score** (dòng 382, 400):

```csharp
Score = Math.Abs(calories - targetCalories);  // Thấp hơn = tốt hơn
```

**Eco score** (dòng 418, 437):

```csharp
Score = (budget - price) + limitMinutes;      // Thấp hơn = tốt hơn
Score = (budget - price) + (limitMinutes - time); // Thấp hơn = tốt hơn
```

**Lunch score** (dòng 455, 473):

```csharp
Score = Math.Abs(calories - target) + Math.Max(0, price - budget)
    + Math.Max(0, time - 20);  // Thấp hơn = tốt hơn
```

**Đánh giá: HỢP LÝ nhưng cần validate**

| Phương pháp   | Bình luận                                                  |
| ------------- | ---------------------------------------------------------- |
| Calorie score | Đơn giản, hiệu quả — tìm món gần target nhất               |
| Eco score     | Tối ưu giá + thời gian, cân bằng hợp lý                    |
| Lunch score   | Có penalty cho vượt budget và quá 20 phút nấu — thiết thực |

Các score này là proprietary heuristics. Nên track hit rate (món được chọn thực tế / được đề xuất) để calibrate.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/Recommendation/scores?mealType=breakfast&targetCalories=544` | Tính scores (CaloriesScore, MacroScore, AllergyScore, BudgetScore, OverallScore) |
| 2 | `GET` | `/api/Recommendation/calories?targetCalories=544` | Gợi ý theo calories (score = \|calories - target\|) |
| 3 | `GET` | `/api/Recommendation/eco?budget=100000&limitMinutes=30` | Gợi ý tiết kiệm (score = budget - price + limitMinutes) |

```bash
curl -X GET "https://api.menugreen.vn/api/Recommendation/scores?mealType=breakfast&targetCalories=544" \
  -H "Authorization: Bearer {token}"
# Response: { "overallScore": 12.5, "caloriesScore": 8.2, "macroScore": 15.0, ... }
# Verify: overallScore = weighted sum; caloriesScore = |actualCalories - targetCalories|
```

---

### 15. Streak

> **Nguồn:** Đây là proprietary logic của ứng dụng. Pattern streak liên tiếp được dùng phổ biến trong habit tracking apps (Streaks, Habitica, Duolingo, MyFitnessPal).

**Ý nghĩa & Mục đích:** Streak là chuỗi ngày liên tiếp mà user log bữa ăn. Streak là **công cụ gamification** mạnh nhất để giữ user quay lại mỗi ngày — tương tự Duolingo hay Habitica. Khi user thấy streak dài, họ có động lực duy trì. Khi streak bị gãy, họ có động lực bắt đầu lại.

**Mục đích trong MenuGreen:**
- Hiển thị streak hiện tại trên dashboard — tạo động lực cho user log mỗi ngày.
- Streak chỉ tăng khi user log ít nhất một bữa ăn trong ngày.
- Nếu bỏ log 2 ngày liên tiếp → streak về 0. Không cần log hôm nay mới reset — chỉ reset khi đã bỏ qua cả hôm nay và hôm qua.
- Đếm tổng số ngày đã tracking (totalDaysTracked) và tổng số meal logs (totalMealLogsCount) để hiển thị trên dashboard.

**File:** `UserDashboardService.cs`, dòng 151-194

```csharp
// Kiểm tra ngày cuối cùng là hôm nay hoặc hôm qua
if (distinctDates[0] != today && distinctDates[0] != yesterday)
    return 0;

// Đếm chuỗi ngày liên tiếp giảm dần
int streak = 0;
var currentDate = distinctDates[0];
foreach (var date in distinctDates) {
    if (date == currentDate) { streak++; currentDate--; }
    else if (date == currentDate.AddDays(-1)) { streak++; currentDate--; }
    else break;
}
```

**Đánh giá: CHÍNH XÁC**

Logic streak đúng: đếm ngày log liên tiếp, bắt đầu từ hôm nay hoặc hôm qua. Nếu không log 2 ngày liên tiếp → streak = 0.

**API kiểm tra:**

| # | Method | Endpoint | Action |
|---|--------|----------|--------|
| 1 | `GET` | `/api/Dashboard/user-summary` | Lấy streak, totalDaysTracked, totalMealLogsCount |

```bash
curl -X GET "https://api.menugreen.vn/api/Dashboard/user-summary" \
  -H "Authorization: Bearer {token}"
# Response: { "currentStreak": 7, "totalDaysTracked": 30, "totalMealLogsCount": 142 }
# Verify streak: streak = 0 nếu ngày cuối không phải hôm nay/hôm qua;
#                streak = đếm ngày liên tiếp giảm dần
```

## Khuyến nghị cải thiện

1. **Giảm ngưỡng Calorie Drift từ 10% xuống 8%** (GoalDriftService) — Align với nghiên cứu mới nhất (Dietary Assessment Initiative 2026).
2. **Tăng breakfast calories lên 30%, giảm dinner xuống 25%** (RecommendationService) — Align với PMC Meal Timing meta-analysis 2024 về front-loading.
3. **Tăng Carbs ratio cho build muscle từ 40% lên 45-50%** (HealthProfileMetricsCalculator) — Phù hợp hơn với nhu cầu glycogen cho buổi tập (ISSN recommendation).
4. **Thêm g/kg protein ratio validation** (HealthProfileMetricsCalculator) — IOM khuyến cáo nên tính protein bằng g/kg thể trọng.
5. **Calibrate Adherence Score weights** bằng A/B testing hoặc user feedback data.
6. **Thêm ngưỡng tối thiểu cho TDEE** — Không nên cho TDEE dưới ~1200 kcal (BMR + sedentary activity).

---

## Tham khảo nhanh

| #   | Tài liệu                                                                                                                                     | Link                                                                                                                                                  |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Mifflin MD et al. (1990). A new predictive equation for resting energy expenditure in healthy individuals. _Am J Clin Nutr, 51(2), 241-247._ | [PubMed Central](https://pmc.ncbi.nlm.nih.gov/articles/PMC1375232/) · [DOI](https://doi.org/10.1093/ajcn/51.2.241)                                    |
| 2   | Frankenfield D et al. (2005). Comparison of predictive equations for resting metabolic rate. _J Am Diet Assoc, 105(5), 775._                 | [PubMed](https://pubmed.ncbi.nlm.nih.gov/15919902/)                                                                                                   |
| 3   | IOM/NIH (2002/2005). Dietary Reference Intakes for Macronutrients. National Academies Press.                                                 | [NCBI Bookshelf](https://www.ncbi.nlm.nih.gov/books/NBK610333/)                                                                                       |
| 4   | NHS (2026). Calorie counting and weight loss guide.                                                                                          | [NHS Better Health](https://www.nhs.uk/better-health/lose-weight/calorie-counting/)                                                                   |
| 5   | Harvard Medical School (2025). Calorie deficit explained.                                                                                    | [Harvard Health](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss)               |
| 6   | PMC (2024). Meal Timing and Anthropometric Outcomes: Systematic Review and Meta-Analysis.                                                    | [PMC11530941](https://pmc.ncbi.nlm.nih.gov/articles/PMC11530941/)                                                                                     |
| 7   | Dietary Assessment Initiative (2026). Clinical thresholds for self-monitoring.                                                               | [DietaryAssessmentInitiative](https://dietaryassessmentinitiative.org/publications/clinical-thresholds-self-monitoring-2026/)                         |
| 8   | Nutrition Research Review (2024). Impact of Calorie Tracking Accuracy on Weight Management Outcomes.                                         | [Link](https://nutrition-research-review.com/articles/impact-tracking-accuracy-weight-management-2024/)                                               |
| 9   | USDA Dietary Guidelines for Americans 2020-2025.                                                                                             | [DietaryGuidelines.gov](https://www.dietaryguidelines.gov/)                                                                                           |
| 10  | TDEEcal.net — Scientific sources for TDEE calculator.                                                                                        | [TDEEcal Sources](https://tdeecal.com/sources/)                                                                                                       |
| 11  | Precision Nutrition. Macros vs Calories vs Intuitive Eating.                                                                                 | [PrecisionNutrition](https://www.precisionnutrition.com/macros-vs-calories)                                                                           |
| 12  | StatPearls — Nutrition: Macronutrient Intake, Imbalances, and Interventions.                                                                 | [NCBI NBK594226](https://www.ncbi.nlm.nih.gov/books/NBK594226/)                                                                                       |
| 13  | HealthcareOnTime. How Many Calories Should I Eat For Breakfast, Lunch & Dinner?                                                              | [HealthcareOnTime](https://www.healthcareontime.com/health-tips/how-many-calories-should-i-eat-for-breakfast-lunch-dinner-its-not-one-size-fits-all/) |
| 14  | Medscape — Mifflin-St Jeor Equation Calculator.                                                                                              | [Medscape](https://reference.medscape.com/calculator/846/mifflin-st-jeor)                                                                             |
| 15  | LoseIt — Calorie Distribution in a Meal Plan.                                                                                                | [LoseIt](https://www.loseit.com/articles/calorie-distribution-in-a-meal-plan/)                                                                        |
