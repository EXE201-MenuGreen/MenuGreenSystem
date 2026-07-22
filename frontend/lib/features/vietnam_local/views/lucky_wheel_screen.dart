import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

class LuckyWheelScreen extends StatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  final _repository = LuckyWheelRepository();
  final TextEditingController _budgetController = TextEditingController();

  List<LuckyWheelFood> _rawFoods = [];
  List<LuckyWheelFood> _foods = [];
  bool _loading = true;
  String? _errorMessage;
  int? _targetBudget;

  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  double _currentRotation = 0;
  bool _spinning = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.decelerate,
    );
    _loadFoods();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    if (_spinning) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    _rotationController.reset();
    _currentRotation = 0;

    final result = await _repository.getFoods();
    if (result.success && result.data != null && result.data!.isNotEmpty) {
      setState(() {
        _rawFoods = result.data!;
        _filterFoods();
        _loading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.translatedMessage;
        _loading = false;
      });
    }
  }

  void _onBudgetChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(clean);
    setState(() {
      _targetBudget = (parsed != null && parsed > 0) ? parsed : null;
      _filterFoods();
    });
  }

  void _clearBudget() {
    _budgetController.clear();
    setState(() {
      _targetBudget = null;
      _filterFoods();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã bỏ giới hạn giá tiền. Vòng quay áp dụng cho tất cả món ăn!',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _filterFoods() {
    if (_targetBudget == null) {
      _foods = List.from(_rawFoods);
      return;
    }

    final target = _targetBudget!;
    // Cho phép chênh lệch từ 4.000 đến 7.000 VNĐ (dùng tolerance max = 7000 VNĐ)
    const tolerance = 7000;
    final minPrice = math.max(0, target - tolerance);
    final maxPrice = target + tolerance;

    final matched = _rawFoods.where((f) {
      final price = f.estimatedPriceVnd ?? 0;
      return price >= minPrice && price <= maxPrice;
    }).toList();

    if (matched.length >= 2) {
      _foods = matched;
    } else {
      // Nếu không có đủ món trong khoảng ±7000, lấy danh sách các món có giá gần nhất
      final sorted = List<LuckyWheelFood>.from(_rawFoods)
        ..sort((a, b) {
          final diffA = ((a.estimatedPriceVnd ?? 0) - target).abs();
          final diffB = ((b.estimatedPriceVnd ?? 0) - target).abs();
          return diffA.compareTo(diffB);
        });
      _foods = sorted.take(math.min(10, sorted.length)).toList();
    }
  }

  String _formatPrice(int amount) {
    final val = amount < 0 ? 0 : amount;
    return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  void _spin() {
    if (_spinning || _foods.isEmpty) return;

    setState(() {
      _spinning = true;
    });

    final random = math.Random();
    _selectedIndex = random.nextInt(_foods.length);

    final segmentAngle = (2 * math.pi) / _foods.length;
    final targetRotation =
        (8 * math.pi) +
        (2 * math.pi - (_selectedIndex * segmentAngle + segmentAngle / 2));

    _rotationAnimation =
        Tween<double>(
          begin: _currentRotation % (2 * math.pi),
          end: targetRotation,
        ).animate(
          CurvedAnimation(
            parent: _rotationController,
            curve: Curves.decelerate,
          ),
        );

    _rotationController.forward(from: 0).then((_) {
      if (!mounted) return;
      _currentRotation = targetRotation;
      setState(() {
        _spinning = false;
      });
      _showResultDialog(_foods[_selectedIndex]);
    });
  }

  void _showResultDialog(LuckyWheelFood food) {
    String selectedMealType = 'Lunch';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎉', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              'MÓN ĂN QUAY RA',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        food.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (food.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            food.imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      if (food.description != null &&
                          food.description!.isNotEmpty) ...[
                        Text(
                          food.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Năng lượng:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${food.caloriesKcal.toStringAsFixed(0)} kcal',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _macroItem(
                                  'Protein',
                                  '${food.proteinG.toStringAsFixed(1)}g',
                                  Colors.redAccent,
                                ),
                                _macroItem(
                                  'Carbs',
                                  '${food.carbsG.toStringAsFixed(1)}g',
                                  Colors.amberAccent,
                                ),
                                _macroItem(
                                  'Fat',
                                  '${food.fatG.toStringAsFixed(1)}g',
                                  Colors.lightBlueAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (food.estimatedPriceVnd != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Giá dự kiến:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _formatPrice(food.estimatedPriceVnd!),
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Thêm món này vào bữa ăn:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map(
                          (type) {
                            final display = type == 'Breakfast'
                                ? 'Sáng'
                                : type == 'Lunch'
                                ? 'Trưa'
                                : type == 'Dinner'
                                ? 'Tối'
                                : 'Phụ';
                            final isSelected = selectedMealType == type;
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedMealType = type;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  display,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Quay lại',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () async {
                                final applyRes = await _repository
                                    .applySelection(food.id, selectedMealType);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                if (applyRes.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã thêm "${food.name}" vào bữa ăn của hôm nay.',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(applyRes.translatedMessage),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Ăn món này',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Vòng Quay Món Ăn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 28,
              color: Colors.amber,
            ),
            tooltip: 'Đổi danh sách món mới',
            onPressed: _spinning ? null : _loadFoods,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadFoods,
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Hôm nay ăn gì?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hãy quay vòng quay cá nhân hóa để MenuGreen chọn cho bạn món ăn lý tưởng nhất nhé!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    // Budget Filter Input Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _targetBudget != null
                              ? Colors.amber
                              : AppColors.primary.withValues(alpha: 0.4),
                          width: _targetBudget != null ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            onChanged: _onBudgetChanged,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập ngân sách mong muốn (VNĐ)...',
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.amber,
                                size: 24,
                              ),
                              border: InputBorder.none,
                              suffixIcon:
                                  (_targetBudget != null ||
                                      _budgetController.text.isNotEmpty)
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                      tooltip: 'Bỏ giới hạn giá tiền (Clear)',
                                      onPressed: _clearBudget,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Wheel + Indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CustomPaint(
                                  painter: _WheelPainter(foods: _foods),
                                ),
                              ),
                            );
                          },
                        ),
                        // Wheel Center Cap
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E293B),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 34,
                          ),
                        ),
                        // Wheel Top Pointer
                        Positioned(
                          top: -8,
                          child: CustomPaint(
                            size: const Size(34, 34),
                            painter: _TrianglePainter(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Buttons section
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _spinning
                                  ? Colors.grey
                                  : AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: _spinning ? 0 : 8,
                              shadowColor: AppColors.primary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            onPressed: _spinning ? null : _spin,
                            child: Text(
                              _spinning ? 'Đang quay...' : 'Quay Ngay 🎲',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber,
                              side: const BorderSide(
                                color: Colors.amber,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _spinning ? null : _loadFoods,
                            icon: const Icon(Icons.refresh_rounded, size: 22),
                            label: const Text(
                              'Đổi danh sách món mới 🔄',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.foods});
  final List<LuckyWheelFood> foods;

  final List<Color> _colors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
    const Color(0xFF6366F1),
    const Color(0xFF84CC16),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (foods.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final anglePerSegment = (2 * math.pi) / foods.length;

    for (int i = 0; i < foods.length; i++) {
      final paint = Paint()
        ..color = _colors[i % _colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * anglePerSegment;
      canvas.drawArc(rect, startAngle, anglePerSegment, true, paint);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + anglePerSegment / 2);

      final textSpan = TextSpan(
        text: foods[i].name.length > 14
            ? '${foods[i].name.substring(0, 12)}...'
            : foods[i].name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(1, 1)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout();

      canvas.translate(radius * 0.48, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);

      canvas.restore();
    }

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
