import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../models/vietnam_local_models.dart';
import '../providers/planned_vs_actual_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/range_picker_field.dart';
import '../widgets/section_header.dart';

/// Planned vs Actual Insights — `2.17 Planned vs Actual Analytics`.
class PlannedVsActualScreen extends StatefulWidget {
  const PlannedVsActualScreen({super.key});

  @override
  State<PlannedVsActualScreen> createState() => _PlannedVsActualScreenState();
}

class _PlannedVsActualScreenState extends State<PlannedVsActualScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlannedVsActualProvider>().loadAll();
    });
  }

  Future<void> _openMonthlyReport() async {
    final provider = context.read<PlannedVsActualProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final result = await provider.getMonthlyReport(
      month: now.month,
      year: now.year,
    );
    if (!mounted) return;
    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Báo cáo tháng đã được tải.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.translatedMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Báo cáo kế hoạch vs thực tế',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            onPressed: _openMonthlyReport,
            tooltip: 'Báo cáo tháng',
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PlannedVsActualProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.loadAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RangePickerField(
                      from: provider.from,
                      to: provider.to,
                      onChanged: (from, to) {
                        provider.setRange(from, to);
                        provider.loadAll();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  if (!provider.isLoading) ...[
                    _buildAdherence(provider.adherence),
                    const SizedBox(height: 16),
                    _buildSummary(provider.summary),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: 'Phân tích lệch',
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: 12),
                    _buildDrift(provider.drift),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: 'Gợi ý khắc phục',
                      icon: Icons.bolt,
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendations(provider.recommendations),
                    const SizedBox(height: 24),
                    _buildRecalibrate(provider),
                  ],
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdherence(AdherenceScore? adherence) {
    if (adherence == null) {
      return const SizedBox.shrink();
    }
    final rating = adherence.rating;
    Color color = AppColors.primary;
    if (rating == 'EXCELLENT') {
      color = const Color(0xFF15803D);
    } else if (rating == 'GOOD') {
      color = const Color(0xFF0891B2);
    } else if (rating == 'FAIR') {
      color = const Color(0xFFEAB308);
    } else {
      color = const Color(0xFFDC2626);
    }
    return InfoCard(
      icon: Icons.scoreboard,
      title: 'Điểm bám sát',
      subtitle: 'Xếp hạng: $rating',
      value: adherence.overallScore.toStringAsFixed(0),
      footnote: adherence.feedback.isEmpty
          ? null
          : ApiMessageTranslator.translate(adherence.feedback),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSubMetric('Hoàn thành bữa', adherence.mealCompletionRate),
          _buildSubMetric('Calo', adherence.calorieDeviationScore),
          _buildSubMetric('Macro', adherence.macroDeviationScore),
          _buildSubMetric('Ngoài kế hoạch', adherence.unplannedPenaltyScore),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(PlannedVsActualSummary? summary) {
    if (summary == null) {
      return const SizedBox.shrink();
    }
    return InfoCard(
      icon: Icons.compare_arrows,
      title: 'Tổng khoảng thời gian',
      subtitle: '${_formatDate(summary.from)} → ${_formatDate(summary.to)}',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMacroBlock(
                  'Kế hoạch',
                  summary.totalPlanned.caloriesKcal,
                  summary.totalPlanned.proteinG,
                  summary.totalPlanned.carbsG,
                  summary.totalPlanned.fatG,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroBlock(
                  'Thực tế',
                  summary.totalActual.caloriesKcal,
                  summary.totalActual.proteinG,
                  summary.totalActual.carbsG,
                  summary.totalActual.fatG,
                  const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          if (summary.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...summary.details.map((e) {
              final diff = (e.actual.caloriesKcal - e.planned.caloriesKcal).abs();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(e.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      diff < 1
                          ? 'Khớp'
                          : '${e.actual.caloriesKcal.toStringAsFixed(0)} vs '
                              '${e.planned.caloriesKcal.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: diff < 1
                            ? AppColors.primary
                            : (e.actual.caloriesKcal > e.planned.caloriesKcal
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0891B2)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroBlock(
    String label,
    double calories,
    double protein,
    double carbs,
    double fat,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 18,
            ),
          ),
          Text(
            'P ${protein.toStringAsFixed(0)} • C ${carbs.toStringAsFixed(0)} '
            '• F ${fat.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrift(DriftAnalysis? drift) {
    if (drift == null) {
      return const SizedBox.shrink();
    }
    return InfoCard(
      icon: Icons.warning_amber,
      title: 'Nguyên nhân lệch',
      subtitle:
          '${drift.skippedMealsCount} bỏ bữa • ${drift.unplannedIntakeCount} ăn ngoài'
          ' • ${drift.substitutedItemsCount} thay thế • ${drift.portionMismatchesCount} sai khẩu phần',
      child: Column(
        children: [
          if (drift.skippedMeals.isNotEmpty)
            _buildListSection('Bữa bị bỏ', drift.skippedMeals
                .take(3)
                .map((e) =>
                    '${_formatDate(e.date)} • ${e.mealType}: ${e.itemName} '
                    '(${e.targetCalories} kcal)')
                .toList()),
          if (drift.unplannedIntakes.isNotEmpty)
            _buildListSection(
              'Ăn ngoài kế hoạch',
              drift.unplannedIntakes
                  .take(3)
                  .map((e) =>
                      '${_formatDate(e.loggedAt)} • ${e.mealType}: '
                      '${e.itemName} (${e.caloriesKcal.toStringAsFixed(0)} kcal)')
                  .toList(),
            ),
          if (drift.substitutedItems.isNotEmpty)
            _buildListSection(
              'Đã thay thế',
              drift.substitutedItems
                  .take(3)
                  .map((e) =>
                      '${_formatDate(e.date)} • ${e.plannedItemName} → '
                      '${e.actualItemName}')
                  .toList(),
            ),
          if (drift.portionMismatches.isNotEmpty)
            _buildListSection(
              'Sai khẩu phần',
              drift.portionMismatches
                  .take(3)
                  .map((e) =>
                      '${_formatDate(e.date)} • ${e.itemName}: '
                      '${e.percentDeviation > 0 ? '+' : ''}${e.percentDeviation.toStringAsFixed(0)}%')
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $e',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(PlannedVsActualRecommendations? recs) {
    if (recs == null) {
      return const SizedBox.shrink();
    }
    final insights = recs.insights.map(ApiMessageTranslator.translate).toList();
    final steps =
        recs.actionableSteps.map(ApiMessageTranslator.translate).toList();
    return InfoCard(
      icon: Icons.tips_and_updates,
      title: 'Khuyến nghị từ hệ thống',
      subtitle: recs.summaryMessage.isEmpty
          ? null
          : ApiMessageTranslator.translate(recs.summaryMessage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insights.isNotEmpty) ...[
            const Text(
              'Phân tích',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            ...insights.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $e',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Hành động',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            ...steps.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '✓ $e',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecalibrate(PlannedVsActualProvider provider) {
    return InfoCard(
      icon: Icons.refresh,
      title: 'Hiệu chỉnh calo/macro tự động',
      subtitle: provider.lastRecalibration == null
          ? 'Áp dụng thuật toán Recalibration dựa trên cân nặng tuần qua.'
          : _summaryOfRecalibration(provider.lastRecalibration!),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: provider.isLoading ? null : provider.recalibrate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: provider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text(
            'Chạy hiệu chỉnh',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _summaryOfRecalibration(Map<String, dynamic> data) {
    try {
      final prev = data['previousTargetCalories'] ?? data['PreviousTargetCalories'];
      final next = data['newTargetCalories'] ?? data['NewTargetCalories'];
      if (prev == null || next == null) return 'Đã chạy hiệu chỉnh.';
      return '${prev.toString()} kcal → ${next.toString()} kcal';
    } catch (_) {
      return 'Đã chạy hiệu chỉnh.';
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  // Suppress unused import lint
  // ignore: unused_element
  String _safeJson(Map<String, dynamic> data) => jsonEncode(data);
}
