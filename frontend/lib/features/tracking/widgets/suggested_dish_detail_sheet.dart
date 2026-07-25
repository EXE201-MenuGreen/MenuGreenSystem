import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/cv_suggested_dish.dart';

typedef SuggestedDishAction = Future<bool> Function(
  CvSuggestedDish dish,
  double portionMultiplier,
);

/// Carries the result of the [SuggestedDishDetailSheet] back to the caller
/// once the sheet pops, so the caller can show appropriate feedback.
///
/// - [success] = true  → the user committed an action that ran without error.
/// - [success] = false → the user explicitly cancelled or some inline flow
///   did not produce a confirmation (e.g. cancelled a "Replace lunch?"
///   dialog). The sheet has already been dismissed; the caller is expected
///   to surface a non-blocking "vui lòng thực hiện lại" hint if desired.
class SheetActionResult {
  const SheetActionResult({
    required this.action,
    required this.success,
    this.errorMessage,
  });

  final String action;
  final bool success;
  final String? errorMessage;

  factory SheetActionResult.cancelled() => const SheetActionResult(
        action: 'cancelled',
        success: false,
      );
}

class SuggestedDishDetailSheet extends StatefulWidget {
  const SuggestedDishDetailSheet({
    super.key,
    required this.dish,
    required this.officeMode,
    required this.onUseToday,
    this.onAddToOfficePlan,
    this.onSaveMealTemplate,
  });

  final CvSuggestedDish dish;
  final bool officeMode;
  final SuggestedDishAction onUseToday;
  final SuggestedDishAction? onAddToOfficePlan;
  final SuggestedDishAction? onSaveMealTemplate;

  @override
  State<SuggestedDishDetailSheet> createState() =>
      _SuggestedDishDetailSheetState();
}

class _SuggestedDishDetailSheetState
    extends State<SuggestedDishDetailSheet> {
  static const _portions = <double>[0.5, 1, 1.5, 2];

  double _portionMultiplier = 1;
  String? _runningAction;
  String? _actionFeedback;
  bool _feedbackIsError = false;

  CvSuggestedDish get dish => widget.dish;

  Future<void> _run(
    String action,
    SuggestedDishAction callback,
  ) async {
    if (_runningAction != null) return;
    setState(() {
      _runningAction = action;
      _actionFeedback = null;
      _feedbackIsError = false;
    });
    var success = false;
    String? errorMessage;
    try {
      success = await callback(dish, _portionMultiplier);
    } catch (error) {
      success = false;
      errorMessage = error
          .toString()
          .replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _runningAction = null);
    }
    if (!mounted) return;

    if (success) {
      Navigator.pop<SheetActionResult>(
        context,
        SheetActionResult(action: action, success: true),
      );
      return;
    }

    // Failure path: keep the sheet open so the user can retry, but surface
    // a clear inline message + remember the error so the caller can show a
    // snackbar if it pops the sheet via other means (back button / X).
    final fallbackMessage =
        'Món ăn chưa được lưu, vui lòng thực hiện lại.';
    setState(() {
      _actionFeedback = errorMessage ?? fallbackMessage;
      _feedbackIsError = true;
    });
    // Also flash a snackbar so the user is sure the previous attempt failed
    // even if the inline banner is below the fold.
    _showActionSnackBar(
      message: errorMessage ?? fallbackMessage,
      isError: true,
    );
  }

  void _showActionSnackBar({required String message, required bool isError}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: isError
            ? SnackBarAction(
                label: 'ĐÓNG',
                textColor: Colors.white,
                onPressed: messenger.hideCurrentSnackBar,
              )
            : null,
      ),
    );
  }

  void _handleSheetDismissed() {
    // The sheet is being popped (back gesture / X button). If the user has
    // not finished any action, dismiss silently — no noisy error toasts.
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    final isSafe = dish.isSafeForUser;
    return PopScope(
      canPop: _runningAction == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _handleSheetDismissed();
      },
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSafetyNotice(isSafe),
                      const SizedBox(height: 18),
                      Text(
                        dish.tenMonAn,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dish.moTaNgan,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPortionSelector(),
                      const SizedBox(height: 18),
                      _buildNutrition(),
                      const SizedBox(height: 24),
                      _buildIngredients(),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildActions(isSafe),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.officeMode
                  ? 'Món gợi ý cho bữa trưa'
                  : 'Chi tiết món gợi ý',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _runningAction == null
                ? () => Navigator.pop(context, SheetActionResult.cancelled())
                : null,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNotice(bool isSafe) {
    final color = isSafe ? AppColors.primary : Colors.redAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSafe ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSafe
                      ? 'Phù hợp với hồ sơ dị ứng của bạn'
                      : 'Không thể chọn món này',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isSafe && dish.matchedAllergens.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Phát hiện: ${dish.matchedAllergens.join(', ')}',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khẩu phần dự kiến',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _portions
              .map(
                (portion) => ChoiceChip(
                  label: Text(
                    '${portion.toStringAsFixed(portion == portion.roundToDouble() ? 0 : 1)} phần',
                  ),
                  selected: _portionMultiplier == portion,
                  onSelected: _runningAction == null
                      ? (_) => setState(() => _portionMultiplier = portion)
                      : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNutrition() {
    final nutrition = dish.thongTinDinhDuongMonAn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dinh dưỡng ước tính',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric(
                'Năng lượng',
                '${(nutrition.tongCalories * _portionMultiplier).round()} kcal',
              ),
              _metric(
                'Protein',
                '${(nutrition.proteinG * _portionMultiplier).toStringAsFixed(1)} g',
              ),
              _metric(
                'Carbs',
                '${(nutrition.carbsG * _portionMultiplier).toStringAsFixed(1)} g',
              ),
              _metric(
                'Chất béo',
                '${(nutrition.fatG * _portionMultiplier).toStringAsFixed(1)} g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nguyên liệu cần dùng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${dish.nguyenLieuSuDung.length} nguyên liệu',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (dish.nguyenLieuSuDung.isEmpty)
          const Text(
            'Chưa có thông tin nguyên liệu chi tiết.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...dish.nguyenLieuSuDung.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF6EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ingredient.ten,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${(ingredient.khoiLuongG * _portionMultiplier).round()} g',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(bool isSafe) {
    final canRun = isSafe && _runningAction == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_actionFeedback != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: (_feedbackIsError
                        ? Colors.redAccent
                        : AppColors.primary)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_feedbackIsError
                          ? Colors.redAccent
                          : AppColors.primary)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _feedbackIsError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 20,
                    color: _feedbackIsError
                        ? Colors.redAccent
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _actionFeedback!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: _feedbackIsError
                            ? Colors.redAccent
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng thông báo',
                    onPressed: () => setState(() {
                      _actionFeedback = null;
                      _feedbackIsError = false;
                    }),
                    icon: const Icon(Icons.close, size: 18),
                    color: _feedbackIsError
                        ? Colors.redAccent
                        : AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canRun
                  ? () => _run('today', widget.onUseToday)
                  : null,
              icon: _actionIcon('today', Icons.lunch_dining_outlined),
              label: Text(
                widget.officeMode
                    ? 'Dùng cho bữa trưa hôm nay'
                    : 'Thêm vào bữa ăn',
              ),
            ),
          ),
          if (widget.officeMode && widget.onAddToOfficePlan != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canRun
                    ? () => _run('plan', widget.onAddToOfficePlan!)
                    : null,
                icon: _actionIcon('plan', Icons.route_outlined),
                label: const Text('Thêm vào kế hoạch cơm hộp'),
              ),
            ),
          ],
          if (widget.onSaveMealTemplate != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: canRun
                  ? () => _run('template', widget.onSaveMealTemplate!)
                  : null,
              icon: _actionIcon('template', Icons.bookmark_add_outlined),
              label: const Text('Lưu vào mẫu bữa ăn'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionIcon(String action, IconData fallback) {
    if (_runningAction != action) return Icon(fallback, size: 19);
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
