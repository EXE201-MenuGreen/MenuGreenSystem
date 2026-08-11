String formatNutritionFacts({
  required num? quantityG,
  required num? caloriesKcal,
  required num? proteinG,
  required num? carbsG,
  required num? fatG,
}) {
  return <String>[
    '${formatNutritionNumber(quantityG)} g',
    '${formatNutritionNumber(caloriesKcal)} kcal',
    'P ${formatNutritionNumber(proteinG)} g',
    'C ${formatNutritionNumber(carbsG)} g',
    'F ${formatNutritionNumber(fatG)} g',
  ].join(' · ');
}

String formatNutritionNumber(num? value) {
  if (value == null) return '—';
  final number = value.toDouble();
  if (!number.isFinite) return '—';
  if (number == number.roundToDouble()) return number.round().toString();
  return number.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
