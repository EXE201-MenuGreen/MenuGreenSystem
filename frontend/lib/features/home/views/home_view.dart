import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _userName = 'MinMin'; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('full_name');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCalorieCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Bữa ăn đề xuất', 'Tất cả'),
            const SizedBox(height: 16),
            _buildRecommendedMeal(context),
            const SizedBox(height: 32),
            _buildSectionHeader('Lựa chọn khác', ''),
            const SizedBox(height: 16),
            _buildOtherOptions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.progressBackground,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), // Dummy avatar
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHÀO BUỔI SÁNG!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_userName, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.progressBackground.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_none, color: AppColors.textDark),
        )
      ],
    );
  }

  Widget _buildCalorieCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TIẾN ĐỘ CALO HÔM NAY', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text('1.200 ', style: TextStyle(color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('/ 1.850 kcal', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Còn lại', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('650 kcal', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 1200 / 1850,
              backgroundColor: AppColors.progressBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroInfo('PROTEIN', '85g', '120g'),
              _buildMacroInfo('CARBS', '140g', '220g'),
              _buildMacroInfo('CHẤT BÉO', '42g', '60g'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String current, String total) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('$current ', style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('/ $total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        if (action.isNotEmpty)
          Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildRecommendedMeal(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: AppColors.progressBackground,
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 48), // Placeholder for image
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('GỢI Ý BỮA TRƯA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Salad Ức Gà Áp Chảo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Row(
                      children: [
                        Icon(Icons.star_border, size: 16, color: AppColors.textDark),
                        SizedBox(width: 4),
                        Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('20 phút', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    SizedBox(width: 16),
                    Icon(Icons.local_fire_department_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('450 kcal', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Giàu protein chất lượng cao và chất xơ tự nhiên, giúp bạn duy trì năng lượng và hỗ trợ cơ bắp suốt buổi chiều.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Xem chi tiết công thức',
                    onPressed: () {},
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOtherOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildSmallMealCard('BỮA PHỤ', 'Smoothie Bơ Hạt', '220 kcal • 5 phút'),
          const SizedBox(width: 16),
          _buildSmallMealCard('ĂN CHAY', 'Poke Chay Cầu Vồng', '380 kcal • 15 phút'),
          const SizedBox(width: 16),
          _buildSmallMealCard('THUẦN CHAY', 'Salad Đậu Hũ', '250 kcal • 10 phút'),
        ],
      ),
    );
  }

  Widget _buildSmallMealCard(String tag, String title, String meta) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.progressBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Icon(Icons.fastfood_outlined, color: Colors.white, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
