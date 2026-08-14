import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/main_screen.dart';
import '../providers/meal_plan_provider.dart';

/// Reloads server-backed plan data before opening the Meal Plan tab.
Future<void> openFreshMealPlan(BuildContext context) async {
  await context.read<MealPlanProvider>().refreshAfterExternalMutation();
  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
    (route) => false,
  );
}
