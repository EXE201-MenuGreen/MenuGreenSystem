import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../profile/views/allergies_screen.dart';
import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';
import '../widgets/allergy_risk_badge.dart';
import '../widgets/discover_food_filters_sheet.dart';
import 'favorites_screen.dart';
import 'food_detail_screen.dart';
import 'ingredient_detail_screen.dart';
import 'recipe_detail_screen.dart';
import 'recommendation_screen.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => DiscoverViewState();
}

class DiscoverViewState extends State<DiscoverView> with SingleTickerProviderStateMixin {
  final _repository = FoodDiscoveryRepository();
  final _keywordController = TextEditingController();
  late final TabController _tabController;

  final String _allergyMode = 'warn';
  bool _safeOnly = false;
  FoodSearchFilters _foodFilters = const FoodSearchFilters();
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _recipesLoading = false;
  bool _ingredientsLoading = false;
  bool _hasAllergies = true;
  String? _error;
  List<FoodItem> _foods = [];
  List<RecipeItem> _recipes = [];
  List<IngredientItem> _ingredients = [];
  int _loadGeneration = 0;
  bool _recipesLoaded = false;
  bool _ingredientsLoaded = false;
  bool? _allergiesCached;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load(initial: true);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && !_recipesLoaded) {
      unawaited(_loadRecipes());
    } else if (_tabController.index == 2 && !_ingredientsLoaded) {
      unawaited(_loadIngredients());
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _keywordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scheduleReload({bool checkAllergy = false}) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      unawaited(_reloadLists(checkAllergy: checkAllergy));
    });
  }

  /// Gọi khi quay lại tab Khám phá sau khi lưu dị ứng ở màn khác.
  Future<void> refreshAllergyStatus() async {
    _allergiesCached = null;
    try {
      final hasAllergies = await _repository
          .hasAllergiesConfigured()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (hasAllergies) _allergiesCached = true;
      setState(() => _hasAllergies = hasAllergies);
    } catch (_) {
      // Giữ trạng thái hiện tại nếu mạng lỗi.
    }
  }

  String get _effectiveAllergyMode => _safeOnly ? 'hide' : _allergyMode;

  String? get _keyword =>
      _keywordController.text.trim().isEmpty ? null : _keywordController.text.trim();

  Future<void> _load({bool initial = false}) async {
    await _reloadLists(initial: initial, checkAllergy: true);
  }

  Future<void> _reloadLists({
    bool initial = false,
    bool checkAllergy = false,
  }) async {
    final gen = ++_loadGeneration;
    if (!mounted) return;
    setState(() {
      if (initial) {
        _initialLoading = true;
      } else {
        _refreshing = true;
      }
      _error = null;
      _recipesLoaded = false;
      _ingredientsLoaded = false;
    });

    try {
      if (checkAllergy || _allergiesCached != true) {
        final hasAllergies = await _repository
            .hasAllergiesConfigured()
            .timeout(const Duration(seconds: 15));
        if (!mounted || gen != _loadGeneration) return;
        if (hasAllergies) _allergiesCached = true;
        setState(() => _hasAllergies = hasAllergies);
      }

      final foods = await _repository
          .searchFoods(
            keyword: _keyword,
            allergyMode: _effectiveAllergyMode,
            filters: _foodFilters,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _foods = foods;
        _initialLoading = false;
        _refreshing = false;
      });

      if (_tabController.index == 1) {
        unawaited(_loadRecipes(generation: gen));
      } else if (_tabController.index == 2) {
        unawaited(_loadIngredients(generation: gen));
      }
    } on TimeoutException {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _error = 'Máy chủ phản hồi chậm. Kéo xuống hoặc bấm Tải lại.';
        _initialLoading = false;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _error = 'Không tải được dữ liệu. Kiểm tra mạng và thử lại.';
        _initialLoading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _loadRecipes({int? generation}) async {
    final gen = generation ?? _loadGeneration;
    if (!mounted) return;
    setState(() => _recipesLoading = true);
    try {
      final recipes = await _repository
          .searchRecipes(keyword: _keyword, allergyMode: _effectiveAllergyMode)
          .timeout(const Duration(seconds: 20));
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _recipes = recipes;
        _recipesLoading = false;
        _recipesLoaded = true;
      });
    } catch (_) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _recipes = [];
        _recipesLoading = false;
        _recipesLoaded = true;
      });
    }
  }

  Future<void> _loadIngredients({int? generation}) async {
    final gen = generation ?? _loadGeneration;
    if (!mounted) return;
    setState(() => _ingredientsLoading = true);
    try {
      final items = await _repository
          .searchIngredients(keyword: _keyword, allergyMode: _effectiveAllergyMode)
          .timeout(const Duration(seconds: 20));
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _ingredients = items;
        _ingredientsLoading = false;
        _ingredientsLoaded = true;
      });
    } catch (_) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _ingredients = [];
        _ingredientsLoading = false;
        _ingredientsLoaded = true;
      });
    }
  }

  Future<void> _openFoodFilters() async {
    final result = await showDiscoverFoodFiltersSheet(context, initial: _foodFilters);
    if (result == null || !mounted) return;
    setState(() => _foodFilters = result);
    _scheduleReload();
  }

  Future<void> _openAllergies() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AllergiesScreen()),
    );
    if (changed == true) {
      _allergiesCached = null;
      _scheduleReload(checkAllergy: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Khám phá',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Gợi ý cá nhân hóa',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecommendationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
                ),
                IconButton(
                  tooltip: 'Món yêu thích',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    );
                    _scheduleReload();
                  },
                  icon: const Icon(Icons.favorite_border, color: AppColors.primary),
                ),
              ],
            ),
          ),
          if (!_hasAllergies) _buildAllergyBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                hintText: 'Tìm món, công thức...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _keywordController.clear();
                    _scheduleReload();
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              onSubmitted: (_) => _scheduleReload(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Chỉ món an toàn'),
                  selected: _safeOnly,
                  onSelected: (v) {
                    setState(() => _safeOnly = v);
                    _scheduleReload();
                  },
                ),
                ActionChip(
                  avatar: Icon(
                    Icons.tune,
                    size: 18,
                    color: _foodFilters.hasAny ? AppColors.primary : null,
                  ),
                  label: Text(_foodFilters.hasAny ? 'Đã lọc' : 'Lọc món'),
                  onPressed: _openFoodFilters,
                ),
                TextButton.icon(
                  onPressed: _openAllergies,
                  icon: const Icon(Icons.medical_information_outlined, size: 18),
                  label: const Text('Dị ứng'),
                ),
                TextButton(
                  onPressed: _refreshing ? null : () => _reloadLists(checkAllergy: false),
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Món ăn'),
              Tab(text: 'Công thức'),
              Tab(text: 'Nguyên liệu'),
            ],
          ),
          if (_refreshing)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null && _foods.isEmpty
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFoodList(),
                          _buildRecipeList(),
                          _buildIngredientList(),
                        ],
                      ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Thông tin dinh dưỡng và dị ứng mang tính tham khảo, không thay tư vấn y khoa.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chưa khai báo dị ứng — cảnh báo an toàn có thể chưa chính xác.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
          TextButton(onPressed: _openAllergies, child: const Text('Thêm')),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    if (_foods.isEmpty) {
      return const Center(child: Text('Không có món phù hợp.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _foods.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final food = _foods[index];
        return _FoodListTile(
          food: food,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodDetailScreen(
                  foodId: food.id,
                  allergyMode: _effectiveAllergyMode,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecipeList() {
    if (_recipesLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_recipes.isEmpty) {
      return const Center(child: Text('Không có công thức phù hợp.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (recipe.mealType != null) recipe.mealType!,
                  if (recipe.prepTimeMin != null) '${recipe.prepTimeMin} phút',
                ].join(' · '),
              ),
              if (recipe.matchedAllergens.isNotEmpty)
                Text(
                  'Trùng: ${recipe.matchedAllergens.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AllergyRiskBadge(riskLevel: recipe.allergyRiskLevel),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(
                  recipeId: recipe.id,
                  allergyMode: _effectiveAllergyMode,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIngredientList() {
    if (_ingredientsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_ingredients.isEmpty) {
      return const Center(child: Text('Không có nguyên liệu phù hợp.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _ingredients.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _ingredients[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          title: Text(item.nameVi, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (item.category != null) item.category!,
                  if (item.caloriesKcal != null) '${item.caloriesKcal!.round()} kcal',
                  if (item.unitDefault != null) item.unitDefault!,
                ].join(' · '),
              ),
              if (item.matchedAllergens.isNotEmpty)
                Text(
                  'Trùng: ${item.matchedAllergens.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AllergyRiskBadge(riskLevel: item.allergyRiskLevel),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IngredientDetailScreen(
                  ingredientId: item.id,
                  allergyMode: _effectiveAllergyMode,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FoodListTile extends StatelessWidget {
  const _FoodListTile({required this.food, required this.onTap});

  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      title: Text(food.nameVi, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (food.caloriesKcal != null)
            Text('${food.caloriesKcal!.round()} kcal · ${food.proteinG?.round() ?? 0}g đạm'),
          if (food.matchedAllergens.isNotEmpty)
            Text(
              'Trùng: ${food.matchedAllergens.join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
        ],
      ),
      trailing: AllergyRiskBadge(riskLevel: food.allergyRiskLevel),
      onTap: onTap,
    );
  }
}
