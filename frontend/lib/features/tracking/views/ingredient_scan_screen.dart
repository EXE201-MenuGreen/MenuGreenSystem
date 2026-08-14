import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../meal_plan/models/meal_plan_requests.dart';
import '../../meal_plan/models/meal_plan_responses.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../meal_templates/repositories/meal_template_repository.dart';
import '../repositories/nutrition_tracking_repository.dart';
import '../widgets/scan_decorations.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/search_and_log_modal.dart';
import '../widgets/suggested_dish_detail_sheet.dart';
import '../widgets/result_feedback_dialog.dart';

class IngredientScanScreen extends StatefulWidget {
  const IngredientScanScreen({super.key, this.officeMode = false});

  final bool officeMode;

  @override
  State<IngredientScanScreen> createState() => _IngredientScanScreenState();
}

class _IngredientScanScreenState extends State<IngredientScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _repository = NutritionTrackingRepository();
  final _mealPlanRepository = MealPlanRepository();
  final _mealTemplateRepository = MealTemplateRepository();
  bool _loading = false;
  String _loadingStep = '';
  int _loadingElapsedSeconds = 0;
  Timer? _stepTimer;
  Uint8List? _selectedImageBytes;

  // Scan line animation
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 280.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startLoadingSteps() {
    setState(() {
      _loading = true;
      _loadingElapsedSeconds = 0;
      _loadingStep = 'Đang chuẩn bị hình ảnh...';
    });

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final elapsed = timer.tick;
      setState(() {
        _loadingElapsedSeconds = elapsed;
        _loadingStep = switch (elapsed) {
          < 4 => 'Đang chuẩn bị và tải hình ảnh...',
          < 12 => 'AI đang nhận diện các nguyên liệu...',
          < 30 => 'Đang kết hợp nguyên liệu để tìm món phù hợp...',
          < 55 => 'Đang tính toán khẩu phần và dinh dưỡng...',
          _ => 'AI đang hoàn tất kết quả, vui lòng chờ thêm...',
        };
      });
    });
  }

  void _stopLoading() {
    _stepTimer?.cancel();
    if (mounted) {
      setState(() {
        _loading = false;
        _loadingElapsedSeconds = 0;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      await _analyzeImage(image);
    } catch (e) {
      if (mounted) {
        _stopLoading();
        _showErrorSnackBar('Không thể chọn hoặc xử lý ảnh. Vui lòng thử lại!');
      }
    }
  }

  Future<void> _showUploadSourcePicker() async {
    if (_loading) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Chọn ảnh tải lên',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Chọn ảnh từ thư viện trên thiết bị'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Thư viện ảnh'),
                subtitle: const Text('Ảnh và ảnh chụp màn hình trên thiết bị'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _selectedImageBytes = bytes);

    _startLoadingSteps();

    if (widget.officeMode) {
      final result = await _repository.analyzeFoodImage(
        bytes,
        image.name,
        mimeType: _imageMimeType(image),
      );

      if (!mounted) return;
      _stopLoading();

      if (result == null) {
        _showErrorSnackBar('Không thể phân tích hình ảnh. Vui lòng thử lại!');
        return;
      }

      _showResultBottomSheet(result);
      return;
    }

    final result = await _repository.analyzePreparedMealImage(
      bytes,
      image.name,
      mimeType: _imageMimeType(image),
    );

    if (!mounted) return;
    _stopLoading();

    if (result['status'] != 'done' || result['result'] is! Map) {
      _showErrorSnackBar(
        'Chưa thể hoàn tất phân tích món ăn. Vui lòng thử lại.',
      );
      return;
    }

    _showPreparedMealBottomSheet(
      Map<String, dynamic>.from(result['result'] as Map),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showResultBottomSheet(CvInferenceResponse response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ScanResultSheet(
          response: response,
          onLogIngredient: _handleLogIngredient,
          onViewSuggestedDish: _showSuggestedDish,
          scrollController: scrollController,
          officeMode: widget.officeMode,
        ),
      ),
    );
  }

  void _showPreparedMealBottomSheet(Map<String, dynamic> result) {
    final macros = result['total_macros'] is Map
        ? Map<String, dynamic>.from(result['total_macros'] as Map)
        : <String, dynamic>{};
    final ingredients = result['ingredients'] is List
        ? (result['ingredients'] as List).whereType<Map>().toList()
        : const <Map>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result['dish_name']?.toString() ?? 'Món ăn đã quét',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Độ tin cậy ${(100 * _number(result['dish_confidence'])).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildPreparedMealMacros(macros),
              const SizedBox(height: 20),
              const Text(
                'Thành phần suy luận',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...ingredients.map((raw) {
                final ingredient = Map<String, dynamic>.from(raw);
                final grams = _number(ingredient['estimated_grams']);
                return Card(
                  child: ListTile(
                    title: Text(ingredient['name']?.toString() ?? 'Thành phần'),
                    subtitle: Text('${grams.toStringAsFixed(0)} g'),
                  ),
                );
              }),
              if (result['estimation_note']?.toString().isNotEmpty ??
                  false) ...[
                const SizedBox(height: 12),
                Text(
                  result['estimation_note'].toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparedMealMacros(Map<String, dynamic> macros) {
    final calories = _number(macros['calories_kcal']);
    final protein = _number(macros['protein_g']);
    final carbs = _number(macros['carbs_g']);
    final fat = _number(macros['fat_g']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Protein ${protein.toStringAsFixed(1)} g • Carb ${carbs.toStringAsFixed(1)} g • Chất béo ${fat.toStringAsFixed(1)} g',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  double _number(dynamic value) => value is num ? value.toDouble() : 0;

  // --- Handlers for Logging ---

  Future<void> _handleLogIngredient(CvIngredientItem ing) async {
    await _showSearchAndLogDialog(
      context: context,
      keyword: ing.tenNguyenLieu,
      defaultGrams: ing.khoiLuongUocTinhG,
      isRecipe: false,
      isIngredient: true,
    );
  }

  Future<void> _showSuggestedDish(CvSuggestedDish dish) async {
    final result = await showModalBottomSheet<SheetActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SuggestedDishDetailSheet(
        dish: dish,
        officeMode: widget.officeMode,
        onUseToday: _useDishToday,
        onAddToOfficePlan: widget.officeMode ? _addDishToOfficePlan : null,
        onSaveMealTemplate: _saveDishAsMealTemplate,
      ),
    );

    if (!mounted || result == null) return;
    if (result.action == 'cancelled') return; // Silent close (X / back)

    // Dùng Dialog ở root Navigator — không bị Sheet/Dialog/DatePicker che
    if (result.success) {
      final (title, message) = _successInfo(
        result.action,
        dish,
        widget.officeMode,
      );
      await showResultFeedbackDialog(
        context,
        title: title,
        message: message,
        isSuccess: true,
        actionLabel: 'Đóng',
      );
    } else {
      final (title, message) = _errorInfo(
        result.action,
        dish,
        result.errorMessage,
        widget.officeMode,
      );
      await showResultFeedbackDialog(
        context,
        title: title,
        message: message,
        isSuccess: false,
        actionLabel: 'Đóng',
      );
    }
  }

  (String title, String message) _successInfo(
    String action,
    CvSuggestedDish dish,
    bool officeMode,
  ) {
    return switch (action) {
      'today' => (
        'Lưu thành công',
        'Món ăn được lưu vào trang dùng cho bữa trưa hôm nay',
      ),
      'plan' => (
        'Thêm vào kế hoạch',
        'Đã thêm món ăn vào kế hoạch cơm hộp thành công',
      ),
      'template' => (
        'Lưu mẫu bữa ăn',
        'Đã lưu món ăn vào mẫu bữa ăn thành công',
      ),
      _ => ('Thành công', 'Thao tác đã hoàn tất.'),
    };
  }

  (String title, String message) _errorInfo(
    String action,
    CvSuggestedDish dish,
    String? error,
    bool officeMode,
  ) {
    return switch (action) {
      'today' => (
        'Lưu thất bại',
        'Không thể lưu món ăn dùng cho bữa trưa hôm nay. Vui lòng thực hiện lại.',
      ),
      'plan' => (
        'Thêm thất bại',
        'Không thể thêm món ăn vào kế hoạch cơm hộp. Vui lòng thực hiện lại.',
      ),
      'template' => (
        'Lưu thất bại',
        'Không thể lưu món ăn vào mẫu bữa ăn. Vui lòng thực hiện lại.',
      ),
      _ => ('Lỗi', 'Thao tác chưa hoàn thành. Vui lòng thực hiện lại.'),
    };
  }

  Future<bool> _useDishToday(
    CvSuggestedDish dish,
    double portionMultiplier,
  ) async {
    final ingredientWeight = dish.nguyenLieuSuDung.fold<double>(
      0,
      (total, ingredient) => total + ingredient.khoiLuongG,
    );

    if (widget.officeMode) {
      try {
        final baseDishWeight = ingredientWeight > 0 ? ingredientWeight : 100.0;
        final saved = await _savePriorityLunchToOffice(
          dish,
          mealType: 'lunch',
          quantityG: baseDishWeight * portionMultiplier,
          baseDishWeight: baseDishWeight,
        );

        return saved ?? false;
      } catch (error) {
        throw Exception(error.toString().replaceFirst('Exception: ', ''));
      }
    }

    return _showSearchAndLogDialog(
      context: context,
      keyword: dish.tenMonAn,
      defaultGrams:
          (ingredientWeight > 0 ? ingredientWeight : 100) * portionMultiplier,
      isRecipe: true,
      fallbackNutrition: dish.thongTinDinhDuongMonAn,
      fallbackNutritionMultiplier: portionMultiplier,
    );
  }

  Future<bool> _showSearchAndLogDialog({
    required BuildContext context,
    required String keyword,
    required double defaultGrams,
    required bool isRecipe,
    bool isIngredient = false,
    CvNutritionInfo? fallbackNutrition,
    double fallbackNutritionMultiplier = 1,
    MealLogSubmitter? submitter,
    bool syncsOfficePlan = false,
  }) async {
    final logged = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SearchAndLogModal(
        repository: _repository,
        keyword: keyword,
        defaultGrams: defaultGrams,
        isRecipe: isRecipe,
        isIngredient: isIngredient,
        fallbackNutrition: fallbackNutrition,
        fallbackNutritionMultiplier: fallbackNutritionMultiplier,
        submitter: submitter,
        syncsOfficePlan: syncsOfficePlan,
        initialMealType: widget.officeMode ? 'lunch' : 'breakfast',
        onSuccess: () {
          if (!context.mounted) return;
          Navigator.pop(ctx, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.officeMode
                    ? 'Đã thêm món vào bữa trưa hôm nay.'
                    : 'Đã thêm món vào bữa ăn.',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
    return logged ?? false;
  }

  Future<bool?> _savePriorityLunchToOffice(
    CvSuggestedDish dish, {
    required String mealType,
    required double quantityG,
    required double baseDishWeight,
  }) async {
    final today = _dateOnly(DateTime.now());
    final plan = await _officePlanFor(today);
    MealPlanItemDetail? existingMeal;
    for (final item in plan.items) {
      if ((item.mealType ?? '').toLowerCase() == mealType.toLowerCase() &&
          item.plannedDate != null &&
          DateUtils.isSameDay(item.plannedDate, today) &&
          (item.origin ?? '').toLowerCase() == 'office_priority') {
        existingMeal = item;
        break;
      }
    }

    if (existingMeal != null) {
      final replace = await _confirmReplaceLunch(existingMeal, dish);
      if (!replace) return null;
    }

    final scale = quantityG / baseDishWeight;
    await _mealPlanRepository.saveOfficePriorityLunch(
      plan.id,
      OfficeScanMealRequest(
        customName: dish.tenMonAn,
        mealType: mealType,
        plannedDate: today,
        scheduledTime: DateTime(today.year, today.month, today.day, 12),
        quantityG: quantityG,
        caloriesKcal: dish.thongTinDinhDuongMonAn.tongCalories * scale,
        proteinG: dish.thongTinDinhDuongMonAn.proteinG * scale,
        carbsG: dish.thongTinDinhDuongMonAn.carbsG * scale,
        fatG: dish.thongTinDinhDuongMonAn.fatG * scale,
        replaceExisting: existingMeal != null,
        ingredients: dish.nguyenLieuSuDung
            .map(
              (ingredient) => OfficeScanIngredientRequest(
                name: ingredient.ten,
                quantity: ingredient.khoiLuongG * scale,
              ),
            )
            .toList(),
      ),
    );
    return true;
  }

  Future<bool> _addDishToOfficePlan(
    CvSuggestedDish dish,
    double portionMultiplier,
  ) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Chọn ngày dùng bữa trưa',
      cancelText: 'Hủy',
      confirmText: 'Chọn ngày',
    );
    if (selectedDate == null || !mounted) return false;

    try {
      final plan = await _officePlanFor(selectedDate);
      MealPlanItemDetail? existingLunch;
      for (final item in plan.items) {
        if ((item.mealType ?? '').toLowerCase() == 'lunch' &&
            item.plannedDate != null &&
            DateUtils.isSameDay(item.plannedDate, selectedDate) &&
            (item.origin ?? '').toLowerCase() == 'office_scan') {
          existingLunch = item;
          break;
        }
      }
      final baseDishWeight = _dishWeight(dish, 1);
      final quantityG = _dishWeight(dish, portionMultiplier);
      final scale = quantityG / baseDishWeight;
      final request = OfficeScanMealRequest(
        customName: dish.tenMonAn,
        mealType: 'lunch',
        plannedDate: selectedDate,
        scheduledTime: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          12,
        ),
        quantityG: quantityG,
        caloriesKcal:
            dish.thongTinDinhDuongMonAn.tongCalories * portionMultiplier,
        proteinG: dish.thongTinDinhDuongMonAn.proteinG * portionMultiplier,
        carbsG: dish.thongTinDinhDuongMonAn.carbsG * portionMultiplier,
        fatG: dish.thongTinDinhDuongMonAn.fatG * portionMultiplier,
        replaceExisting: existingLunch != null,
        ingredients: dish.nguyenLieuSuDung
            .map(
              (ingredient) => OfficeScanIngredientRequest(
                name: ingredient.ten,
                quantity: ingredient.khoiLuongG * scale,
              ),
            )
            .toList(),
      );

      if (existingLunch != null) {
        final replace = await _confirmReplaceLunch(existingLunch, dish);
        if (!replace) return false;
      }

      await _mealPlanRepository.saveOfficeScanPlanItem(plan.id, request);

      return true;
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MealPlanDetail> _officePlanFor(DateTime date) async {
    final plans = await _mealPlanRepository.getPlans(isActive: true);
    for (final summary in plans) {
      final isOfficePlan =
          summary.title.toLowerCase().contains('cơm hộp') ||
          summary.title.toLowerCase().contains('office');
      final startsBefore =
          summary.startDate == null ||
          !date.isBefore(_dateOnly(summary.startDate!));
      final endsAfter =
          summary.endDate == null || !date.isAfter(_dateOnly(summary.endDate!));
      if (!isOfficePlan || !startsBefore || !endsAfter) continue;
      final detail = await _mealPlanRepository.getPlanDetail(summary.id);
      if (detail != null) return detail;
    }

    final weekStart = _dateOnly(
      date,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _mealPlanRepository.createEmptyPlan(
      CreateEmptyPlanRequest(
        title: 'Kế hoạch cơm hộp Office ${weekStart.day}/${weekStart.month}',
        planType: 'weekly',
        startDate: weekStart,
        endDate: weekEnd,
      ),
    );
  }

  Future<bool> _confirmReplaceLunch(
    MealPlanItemDetail current,
    CvSuggestedDish replacement,
  ) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Thay bữa trưa đã có?'),
            content: Text(
              'Ngày này đang có “${current.displayName}”. '
              'Bạn có muốn thay bằng “${replacement.tenMonAn}” không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Giữ món hiện tại'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Thay món'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _saveDishAsMealTemplate(
    CvSuggestedDish dish,
    double portionMultiplier,
  ) async {
    final mealType = await _chooseTemplateMealType();
    if (mealType == null) return false;
    final mealLabel = _mealTypeLabel(mealType);
    final baseWeight = dish.nguyenLieuSuDung.fold<double>(
      0,
      (total, ingredient) => total + ingredient.khoiLuongG,
    );
    final quantityG = (baseWeight > 0 ? baseWeight : 100) * portionMultiplier;
    final nutrition = dish.thongTinDinhDuongMonAn;
    try {
      await _mealTemplateRepository.create({
        'title': '$mealLabel - ${dish.tenMonAn}',
        'description': dish.moTaNgan.isEmpty
            ? 'Món được lưu từ kết quả quét nguyên liệu.'
            : dish.moTaNgan,
        'mealType': mealType,
        'isActive': true,
        'items': [
          {
            'customName': dish.tenMonAn,
            'sourceType': 'AiScan',
            'mealType': mealType,
            'quantityG': quantityG,
            'caloriesKcal': nutrition.tongCalories * portionMultiplier,
            'proteinG': nutrition.proteinG * portionMultiplier,
            'carbsG': nutrition.carbsG * portionMultiplier,
            'fatG': nutrition.fatG * portionMultiplier,
            'ingredients': dish.nguyenLieuSuDung
                .map(
                  (ingredient) => {
                    'name': ingredient.ten,
                    'quantity': ingredient.khoiLuongG * portionMultiplier,
                    'unit': 'g',
                    'isAvailable': true,
                  },
                )
                .toList(),
            'notes': 'Gợi ý từ quét nguyên liệu',
            'sortOrder': 0,
          },
        ],
      });
      return true;
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> _chooseTemplateMealType() {
    const mealTypes = <(String, String, IconData)>[
      ('Breakfast', 'Bữa sáng', Icons.wb_sunny_outlined),
      ('Lunch', 'Bữa trưa', Icons.lunch_dining_outlined),
      ('Dinner', 'Bữa tối', Icons.nights_stay_outlined),
    ];
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lưu món cho bữa nào?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Món sẽ xuất hiện trong Mẫu bữa ăn với loại bữa bạn chọn.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ...mealTypes.map(
                (type) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    child: Icon(type.$3),
                  ),
                  title: Text(
                    type.$2,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(sheetContext, type.$1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mealTypeLabel(String value) {
    return switch (value) {
      'Breakfast' => 'Bữa sáng',
      'Dinner' => 'Bữa tối',
      _ => 'Bữa trưa',
    };
  }

  double _dishWeight(CvSuggestedDish dish, double multiplier) {
    final total = dish.nguyenLieuSuDung.fold<double>(
      0,
      (sum, ingredient) => sum + ingredient.khoiLuongG,
    );
    return (total > 0 ? total : 100) * multiplier;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanBoxWidth = screenSize.width - 48;
    final scanBoxHeight = screenSize.height * 0.54;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Full View Camera Preview / Image Background
          Positioned.fill(
            child: _selectedImageBytes != null
                ? Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF0FDF4),
                          Color(0xFFF8FAFC),
                          Color(0xFFE2E8F0),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Full View Scanning Viewport Overlay
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: scanBoxWidth,
                height: scanBoxHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Full view viewfinder frame border
                    Container(
                      width: scanBoxWidth,
                      height: scanBoxHeight,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: _selectedImageBytes == null
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedImageBytes == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 36,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Hướng camera về phía nguyên liệu',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),

                    // Animated Scanning Line across full viewport height
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (ctx, child) => Positioned(
                        top:
                            (_scanLineAnimation.value / 280.0) *
                            (scanBoxHeight - 12),
                        left: 4,
                        right: 4,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.9),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Corners of the box (Corner brackets) - Primary color for high contrast
                    const ScanCornerBracket(
                      top: -2,
                      left: -2,
                      isTop: true,
                      isLeft: true,
                      color: AppColors.primary,
                    ),
                    const ScanCornerBracket(
                      top: -2,
                      right: -2,
                      isTop: true,
                      isLeft: false,
                      color: AppColors.primary,
                    ),
                    const ScanCornerBracket(
                      bottom: -2,
                      left: -2,
                      isTop: false,
                      isLeft: true,
                      color: AppColors.primary,
                    ),
                    const ScanCornerBracket(
                      bottom: -2,
                      right: -2,
                      isTop: false,
                      isLeft: false,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top Header Bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                  ),
                ),
                Text(
                  widget.officeMode
                      ? 'Quét nguyên liệu Office'
                      : 'Quét nguyên liệu',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // 4. Instructions & Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 48,
                left: 32,
                right: 32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text instructions
                  Text(
                    widget.officeMode
                        ? 'Chụp nguyên liệu để nhận món phù hợp cho bữa trưa văn phòng'
                        : 'Hướng ống kính về phía nguyên liệu để nhận dạng tự động',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Upload button
                      ScanControlBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'TẢI LÊN',
                        isLightMode: true,
                        onTap: _showUploadSourcePicker,
                      ),

                      // Shutter button (Center)
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // History button
                      ScanControlBtn(
                        icon: Icons.history,
                        label: 'LỊCH SỬ',
                        isLightMode: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Loading Overlay (Light Mode styled)
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.88),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.officeMode
                              ? 'Đang gợi ý món Office'
                              : 'Đang phân tích món ăn',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _loadingStep,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            minHeight: 5,
                            color: AppColors.primary,
                            backgroundColor: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Đã chờ $_loadingElapsedSeconds giây · Thường mất 20–60 giây',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vui lòng giữ màn hình này trong khi AI xử lý.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _imageMimeType(XFile image) {
  final extension = image.name.split('.').last.toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
