# Test Cases - Health Profile, Allergy, and Health Goal

## 1. BMI Test Cases

### Công thức
`BMI = Weight(kg) / Height(m)^2`

| Test Case | Input | Expected Result |
|---|---|---|
| TC-BMI-01 | Height: 170 cm, Weight: 65 kg | BMI ≈ 22.49 |
| TC-BMI-02 | Height: 160 cm, Weight: 80 kg | BMI ≈ 31.25 |
| TC-BMI-03 | Height: 180 cm, Weight: 50 kg | BMI ≈ 15.43 |

## 2. BMR Test Cases

### Công thức Mifflin-St Jeor
- Male: `10*W + 6.25*H - 5*A + 5`
- Female: `10*W + 6.25*H - 5*A - 161`

| Test Case | Input | Expected Result |
|---|---|---|
| TC-BMR-01 | Male, 25 years, 170 cm, 65 kg | BMR ≈ 1628 kcal |
| TC-BMR-02 | Female, 25 years, 170 cm, 65 kg | BMR ≈ 1462 kcal |
| TC-BMR-03 | Nam, 30 years, 175 cm, 75 kg | BMR ≈ 1709 kcal |

## 3. TDEE Test Cases

### Công thức
`TDEE = BMR x Activity Multiplier`

### Activity Multiplier
- Sedentary = `1.2`
- Lightly Active = `1.375`
- Moderately Active = `1.55`
- Very Active = `1.725`

| Test Case | Input | Expected Result |
|---|---|---|
| TC-TDEE-01 | BMR: 1628, Sedentary | TDEE ≈ 1954 kcal |
| TC-TDEE-02 | BMR: 1628, Lightly Active | TDEE ≈ 2239 kcal |
| TC-TDEE-03 | BMR: 1628, Moderately Active | TDEE ≈ 2523 kcal |
| TC-TDEE-04 | BMR: 1628, Very Active | TDEE ≈ 2808 kcal |

## 4. Calories Goal Test Cases

### Logic
- Gain weight: `+300`
- Lose weight: `-500`
- Maintain weight: `+0`
- Build muscle: `+200`

| Test Case | Input | Expected Result |
|---|---|---|
| TC-GOAL-01 | TDEE: 2200, Goal: Gain weight | Calories Goal = 2500 kcal |
| TC-GOAL-02 | TDEE: 2200, Goal: Lose weight | Calories Goal = 1700 kcal |
| TC-GOAL-03 | TDEE: 2200, Goal: Maintain weight | Calories Goal = 2200 kcal |
| TC-GOAL-04 | TDEE: 2200, Goal: Build muscle | Calories Goal = 2400 kcal |

## 5. Macro Distribution Test Cases

### Logic
- Normal goals:
  - Protein = 30%
  - Carbs = 40%
  - Fat = 30%
- Build muscle:
  - Protein = 35%
  - Carbs = 40%
  - Fat = 25%

### Calories per gram
- Protein = 4 kcal/g
- Carbs = 4 kcal/g
- Fat = 9 kcal/g

| Test Case | Input | Expected Result |
|---|---|---|
| TC-MACRO-01 | Calories Goal: 2400, Goal: Maintain weight | Protein 180g, Carbs 240g, Fat 80g |
| TC-MACRO-02 | Calories Goal: 2500, Goal: Gain weight | Protein 188g, Carbs 250g, Fat 83g |
| TC-MACRO-03 | Calories Goal: 2400, Goal: Build muscle | Protein 210g, Carbs 240g, Fat 67g |
| TC-MACRO-04 | Calories Goal: 1700, Goal: Lose weight | Protein 128g, Carbs 170g, Fat 57g |

## 6. Health Profile Test Cases

| Test Case | Input | Expected Result |
|---|---|---|
| TC-HP-01 | Height 170 cm, Weight 65 kg, Body fat 20%, Activity Moderately Active, Goal Maintain weight, Male, Age 25 | BMI ≈ 22.49, BMR ≈ 1628, TDEE ≈ 2523, Calories Goal ≈ 2523 |
| TC-HP-02 | Height 160 cm, Weight 80 kg, Body fat 30%, Activity Lightly Active, Goal Lose weight, Female, Age 30 | BMI ≈ 31.25, BMR ≈ 1484, TDEE ≈ 2041, Calories Goal ≈ 1541 |

## 7. Allergy Management Test Cases

| Test Case | Scenario | Expected Result |
|---|---|---|
| TC-ALG-01 | Add allergy: Seafood | Allergy created successfully |
| TC-ALG-02 | Update allergy from Seafood to Peanut | Allergy name updated to Peanut |
| TC-ALG-03 | Delete an allergy owned by the user | Allergy removed successfully |
| TC-ALG-04 | User A edits User B allergy | Forbidden error |

## 8. Edge Cases

| Test Case | Input | Expected Result |
|---|---|---|
| TC-EDGE-01 | Height = 0 | Validation error / prevent divide by zero |
| TC-EDGE-02 | Weight = 0 | Validation error |
| TC-EDGE-03 | ActivityLevel = "Super Active" | Fallback to default multiplier 1.2 |
| TC-EDGE-04 | Goal = "Bulk" | Default behavior, no special calorie adjustment |
| TC-EDGE-05 | BodyFatPercent empty | System still calculates BMI/BMR/TDEE normally |

## 9. Sample API Payloads

### Update Health Profile
```json
{
  "heightCm": 170,
  "weightKg": 65,
  "bodyFatPercent": 20,
  "activityLevel": "Moderately Active",
  "goal": "Maintain weight"
}
```

### Create Allergy
```json
{
  "name": "Seafood",
  "notes": "Không ăn hải sản",
  "isActive": true
}
```

## 10. Notes

- BMI should be rounded to 2 decimal places.
- BMR, TDEE, and Calories Goal should be returned as integer kcal values.
- Allergy actions must be limited to the authenticated user owner.
- Health goal updates should automatically recalculate calories and macros.
