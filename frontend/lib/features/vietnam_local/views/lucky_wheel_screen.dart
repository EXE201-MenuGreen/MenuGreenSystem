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

class _LuckyWheelScreenState extends State<LuckyWheelScreen> with SingleTickerProviderStateMixin {
  final _repository = LuckyWheelRepository();
  List<LuckyWheelFood> _foods = [];
  bool _loading = true;
  String? _errorMessage;

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
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await _repository.getFoods();
    if (result.success && result.data != null && result.data!.isNotEmpty) {
      setState(() {
        _foods = result.data!;
        _loading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.translatedMessage;
        _loading = false;
      });
    }
  }

  void _spin() {
    if (_spinning || _foods.isEmpty) return;

    setState(() {
      _spinning = true;
    });

    final random = math.Random();
    _selectedIndex = random.nextInt(_foods.length);

    // A segment is 360 / length
    final segmentAngle = (2 * math.pi) / _foods.length;
    // Calculate target angle to place the selected item at the top pointer (angle = -pi/2)
    // The rotation angle must land the segment at the indicator.
    // Indicator is at top (-pi/2). So rotation = -pi/2 - (segmentIndex * segmentAngle + segmentAngle / 2)
    final targetRotation = (8 * math.pi) + (2 * math.pi - (_selectedIndex * segmentAngle + segmentAngle / 2));

    _rotationAnimation = Tween<double>(
      begin: _currentRotation % (2 * math.pi),
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.decelerate,
    ));

    _rotationController.forward(from: 0).then((_) {
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
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B), // Premium dark slate
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      food.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (food.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          food.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.fastfood, color: Colors.white54, size: 40),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (food.description != null && food.description!.isNotEmpty) ...[
                      Text(
                        food.description!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Calories & Macros
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Năng lượng:', style: TextStyle(color: Colors.white70)),
                              Text(
                                '${food.caloriesKcal.toStringAsFixed(0)} kcal',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _macroItem('P', '${food.proteinG.toStringAsFixed(1)}g', Colors.redAccent),
                              _macroItem('C', '${food.carbsG.toStringAsFixed(1)}g', Colors.amberAccent),
                              _macroItem('F', '${food.fatG.toStringAsFixed(1)}g', Colors.lightBlueAccent),
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
                          const Text('Giá dự kiến:', style: TextStyle(color: Colors.white70)),
                          Text(
                            '${food.estimatedPriceVnd!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Choose Meal Slot
                    const Text(
                      'Thêm vào bữa ăn nào:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              display,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Quay lại', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final applyRes = await _repository.applySelection(food.id, selectedMealType);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Close dialog
                    if (applyRes.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm ${food.name} vào bữa ăn của hôm nay.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop(); // Back to dashboard
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(applyRes.translatedMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Ăn món này', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate background
      appBar: AppBar(
        title: const Text('Vòng Quay Món Ăn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadFoods,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Dynamic background circles
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -150,
                      left: -150,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Hôm nay ăn gì?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hãy quay vòng quay cá nhân hóa để MenuGreen chọn cho bạn món ăn lý tưởng nhất nhé!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 40),
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
                                width: 56,
                                height: 56,
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
                                  size: 28,
                                ),
                              ),
                              // Wheel Top Pointer
                              Positioned(
                                top: -8,
                                child: CustomPaint(
                                  size: const Size(30, 30),
                                  painter: _TrianglePainter(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _spinning ? Colors.grey : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: _spinning ? 0 : 8,
                                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              ),
                              onPressed: _spinning ? null : _spin,
                              child: Text(
                                _spinning ? 'Đang quay...' : 'Quay Ngay',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.foods});
  final List<LuckyWheelFood> foods;

  // Curated premium HSL-like color palette
  final List<Color> _colors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF84CC16), // Lime
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (foods.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final anglePerSegment = (2 * math.pi) / foods.length;

    // Draw wheel segments
    for (int i = 0; i < foods.length; i++) {
      final paint = Paint()
        ..color = _colors[i % _colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * anglePerSegment;
      canvas.drawArc(rect, startAngle, anglePerSegment, true, paint);

      // Draw item names text on segment
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Place the text inside the segment (midpoint angle)
      canvas.rotate(startAngle + anglePerSegment / 2);

      // We place the text at 0.65 * radius from the center
      final textSpan = TextSpan(
        text: foods[i].name.length > 14
            ? '${foods[i].name.substring(0, 12)}...'
            : foods[i].name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout();

      // Align the text radially outwards
      canvas.translate(radius * 0.55, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);

      canvas.restore();
    }

    // Outer wheel gold border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700) // Gold pointer
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
