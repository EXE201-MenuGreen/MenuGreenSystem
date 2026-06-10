import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';
import '../widgets/scan_decorations.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/search_and_log_modal.dart';

class IngredientScanScreen extends StatefulWidget {
  const IngredientScanScreen({super.key});

  @override
  State<IngredientScanScreen> createState() => _IngredientScanScreenState();
}

class _IngredientScanScreenState extends State<IngredientScanScreen> with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _repository = NutritionTrackingRepository();
  bool _loading = false;
  String _loadingStep = '';
  Timer? _stepTimer;
  XFile? _selectedImage;

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
    final steps = [
      'Đang kết nối tới máy chủ...',
      'Đang tải hình ảnh lên hệ thống...',
      'Đang chạy mô hình AI nhận dạng nguyên liệu...',
      'Đang tính toán khối lượng ước tính...',
      'Đang đối chiếu hồ sơ dị ứng của bạn...',
      'Đang hoàn tất phân tích dinh dưỡng...',
    ];
    int currentStep = 0;
    setState(() {
      _loading = true;
      _loadingStep = steps[0];
    });

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      currentStep++;
      if (currentStep < steps.length) {
        if (mounted) {
          setState(() {
            _loadingStep = steps[currentStep];
          });
        }
      } else {
        timer.cancel();
      }
    });
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

      setState(() {
        _selectedImage = image;
      });

      _startLoadingSteps();

      final bytes = await image.readAsBytes();
      final result = await _repository.analyzeFoodImage(bytes, image.name);

      _stepTimer?.cancel();
      if (!mounted) return;
      setState(() => _loading = false);

      if (result == null) {
        _showErrorSnackBar('Không thể phân tích hình ảnh. Vui lòng thử lại!');
        return;
      }

      _showResultBottomSheet(result);
    } catch (e) {
      _stepTimer?.cancel();
      if (mounted) {
        setState(() => _loading = false);
        _showErrorSnackBar('Đã xảy ra lỗi khi kết nối tới AI Service.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
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
          onLogSuggestedDish: _handleLogSuggestedDish,
          scrollController: scrollController,
        ),
      ),
    );
  }

  // --- Handlers for Logging ---

  Future<void> _handleLogIngredient(CvIngredientItem ing) async {
    _showSearchAndLogDialog(
      context: context,
      keyword: ing.tenNguyenLieu,
      defaultGrams: ing.khoiLuongUocTinhG,
      isRecipe: false,
    );
  }

  Future<void> _handleLogSuggestedDish(CvSuggestedDish dish) async {
    _showSearchAndLogDialog(
      context: context,
      keyword: dish.tenMonAn,
      defaultGrams: 100, // default portion weight
      isRecipe: true,
    );
  }

  Future<void> _showSearchAndLogDialog({
    required BuildContext context,
    required String keyword,
    required double defaultGrams,
    required bool isRecipe,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SearchAndLogModal(
        repository: _repository,
        keyword: keyword,
        defaultGrams: defaultGrams,
        isRecipe: isRecipe,
        onSuccess: () {
          if (!context.mounted) return;
          Navigator.pop(ctx); // Close search modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã ghi nhận bữa ăn thành công!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. simulated Camera Preview (Dark background, layout)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: _selectedImage != null
                  ? Opacity(
                      opacity: 0.6,
                      // If user selected an image, show it as background
                      child: Image.network(
                        _selectedImage!.path,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Khởi động camera...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),
            ),
          ),

          // 2. Scanning Viewport
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Green box
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF4ADE80), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),

                  // Animated Scanning Line
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (ctx, child) => Positioned(
                      top: _scanLineAnimation.value,
                      left: 2,
                      right: 2,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Corners of the box (Corner brackets)
                  const ScanCornerBracket(top: -2, left: -2, isTop: true, isLeft: true),
                  const ScanCornerBracket(top: -2, right: -2, isTop: true, isLeft: false),
                  const ScanCornerBracket(bottom: -2, left: -2, isTop: false, isLeft: true),
                  const ScanCornerBracket(bottom: -2, right: -2, isTop: false, isLeft: false),

                  // Floating Tooltips (bouncing tags)
                  const Positioned(
                    top: -15,
                    left: 20,
                    child: ScanFloatingTooltip(text: 'Cà chua'),
                  ),
                  const Positioned(
                    bottom: -15,
                    right: 20,
                    child: ScanFloatingTooltip(text: 'Súp lơ'),
                  ),
                ],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  ),
                ),
                const Text(
                  'Quét nguyên liệu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                )
              ],
            ),
          ),

          // 4. Instructions & Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 80, bottom: 48, left: 32, right: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text instructions
                  Text(
                    'Hướng ống kính về phía nguyên liệu để nhận dạng tự động',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
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
                        onTap: () => _pickImage(ImageSource.gallery),
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
                            border: Border.all(color: AppColors.primary, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // History button
                      ScanControlBtn(
                        icon: Icons.history,
                        label: 'LỊCH SỬ',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 5. Loading Overlay
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF4ADE80),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _loadingStep,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
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
