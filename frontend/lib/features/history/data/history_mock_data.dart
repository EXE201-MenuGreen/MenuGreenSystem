import 'package:flutter/material.dart';
import '../models/history_models.dart';

class HistoryMockData {
  static List<HistoryTimelineSection> sectionsForDate(DateTime date) {
    // Demo data aligned with the design mockup.
    return [
      HistoryTimelineSection(
        category: MealCategory.breakfast,
        time: const TimeOfDay(hour: 7, minute: 30),
        isHighlighted: true,
        meals: const [
          HistoryMealEntry(
            id: '1',
            title: 'Ngũ cốc & Trái cây',
            calories: 320,
            portion: '150g',
            time: TimeOfDay(hour: 7, minute: 30),
            category: MealCategory.breakfast,
            imageUrl: 'https://images.unsplash.com/photo-1517686469429-8bdb88b9f907?w=200',
          ),
        ],
      ),
      HistoryTimelineSection(
        category: MealCategory.lunch,
        time: const TimeOfDay(hour: 12, minute: 15),
        meals: const [
          HistoryMealEntry(
            id: '2',
            title: 'Salad Ức Gà Nướng',
            calories: 450,
            portion: '300g',
            time: TimeOfDay(hour: 12, minute: 15),
            category: MealCategory.lunch,
            imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
          ),
          HistoryMealEntry(
            id: '3',
            title: 'Sinh tố Bơ',
            calories: 180,
            portion: '200ml',
            time: TimeOfDay(hour: 12, minute: 15),
            category: MealCategory.lunch,
            imageUrl: 'https://images.unsplash.com/photo-1623065422902-30a2e4daf74b?w=200',
          ),
        ],
      ),
      HistoryTimelineSection(
        category: MealCategory.snack,
        time: const TimeOfDay(hour: 15, minute: 45),
        meals: const [
          HistoryMealEntry(
            id: '4',
            title: 'Táo Đỏ',
            calories: 95,
            portion: '1 quả',
            time: TimeOfDay(hour: 15, minute: 45),
            category: MealCategory.snack,
            imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=200',
          ),
        ],
      ),
    ];
  }
}
