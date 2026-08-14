import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../../../core/services/location_service.dart';
import '../../onboarding/repositories/user_ai_profile_repository.dart';
import '../../profile/views/allergies_screen.dart';
import '../models/food_models.dart';
import '../providers/favorite_food_provider.dart';
import '../repositories/food_discovery_repository.dart';
import '../widgets/allergy_risk_badge.dart';
import '../widgets/discover_food_filters_sheet.dart';
import 'favorites_screen.dart';
import 'food_detail_screen.dart';
import 'ingredient_detail_screen.dart';
import 'recipe_detail_screen.dart';
import 'recommendation_screen.dart';

class DiscoverView extends StatefulWidget {
  final bool isStandalone;
  const DiscoverView({super.key, this.isStandalone = false});

  @override
  State<DiscoverView> createState() => DiscoverViewState();
}

class DiscoverViewState extends State<DiscoverView>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 10;

  final _repository = FoodDiscoveryRepository();
  final _keywordController = TextEditingController();
  final _foodScrollController = ScrollController();
  final _recipeScrollController = ScrollController();
  final _ingredientScrollController = ScrollController();
  late final TabController _tabController;

  final String _allergyMode = 'warn';
  bool _safeOnly = false;
  FoodSearchFilters _foodFilters = const FoodSearchFilters();
  String? _detectedRegion;
  bool _detectingLocation = false;
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _recipesLoading = false;
  bool _ingredientsLoading = false;
  bool _hasAllergies = true;
  String? _error;
  List<FoodItem> _foods = [];
  List<RecipeItem> _recipes = [];
  List<IngredientItem> _ingredients = [];
  int _foodPage = 1;
  int _foodTotalCount = 0;
  int _foodTotalPages = 0;
  int _recipePage = 1;
  int _recipeTotalCount = 0;
  int _recipeTotalPages = 0;
  int _ingredientPage = 1;
  int _ingredientTotalCount = 0;
  int _ingredientTotalPages = 0;
  int _loadGeneration = 0;
  bool _recipesLoaded = false;
  bool _ingredientsLoaded = false;
  bool? _allergiesCached;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    context.read<FavoriteFoodProvider>().load();
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
    _foodScrollController.dispose();
    _recipeScrollController.dispose();
    _ingredientScrollController.dispose();
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
      final hasAllergies = await _repository.hasAllergiesConfigured().timeout(
        const Duration(seconds: 15),
      );
      if (!mounted) return;
      if (hasAllergies) _allergiesCached = true;
      setState(() => _hasAllergies = hasAllergies);
    } catch (_) {
      // Giữ trạng thái hiện tại nếu mạng lỗi.
    }
  }

  String get _effectiveAllergyMode => _safeOnly ? 'hide' : _allergyMode;

  String? get _keyword => _keywordController.text.trim().isEmpty
      ? null
      : _keywordController.text.trim();

  Future<void> _load({bool initial = false}) async {
    await _reloadLists(initial: initial, checkAllergy: true);
  }

  Future<void> _reloadLists({
    bool initial = false,
    bool checkAllergy = false,
    bool resetPages = true,
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
      if (resetPages) {
        _foodPage = 1;
        _recipePage = 1;
        _ingredientPage = 1;
      }
    });

    try {
      if (checkAllergy || _allergiesCached != true) {
        final hasAllergies = await _repository.hasAllergiesConfigured().timeout(
          const Duration(seconds: 15),
        );
        if (!mounted || gen != _loadGeneration) return;
        if (hasAllergies) _allergiesCached = true;
        setState(() => _hasAllergies = hasAllergies);
      }

      final foodsPage = await _repository
          .searchFoodsPage(
            keyword: _keyword,
            allergyMode: _effectiveAllergyMode,
            filters: _foodFilters,
            region: _detectedRegion,
            page: _foodPage,
            pageSize: _pageSize,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _foods = foodsPage.items;
        _foodPage = foodsPage.page;
        _foodTotalCount = foodsPage.totalCount;
        _foodTotalPages = foodsPage.totalPages;
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
      final recipesPage = await _repository
          .searchRecipesPage(
            keyword: _keyword,
            allergyMode: _effectiveAllergyMode,
            page: _recipePage,
            pageSize: _pageSize,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _recipes = recipesPage.items;
        _recipePage = recipesPage.page;
        _recipeTotalCount = recipesPage.totalCount;
        _recipeTotalPages = recipesPage.totalPages;
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
      final itemsPage = await _repository
          .searchIngredientsPage(
            keyword: _keyword,
            allergyMode: _effectiveAllergyMode,
            page: _ingredientPage,
            pageSize: _pageSize,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _ingredients = itemsPage.items;
        _ingredientPage = itemsPage.page;
        _ingredientTotalCount = itemsPage.totalCount;
        _ingredientTotalPages = itemsPage.totalPages;
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

  Future<void> _goToPage(int page) async {
    switch (_tabController.index) {
      case 0:
        if (_refreshing || page < 1 || page > _foodTotalPages) return;
        setState(() => _foodPage = page);
        await _reloadLists(resetPages: false);
        _scrollToTop(_foodScrollController);
        return;
      case 1:
        if (_recipesLoading || page < 1 || page > _recipeTotalPages) return;
        setState(() => _recipePage = page);
        await _loadRecipes();
        _scrollToTop(_recipeScrollController);
        return;
      case 2:
        if (_ingredientsLoading || page < 1 || page > _ingredientTotalPages) {
          return;
        }
        setState(() => _ingredientPage = page);
        await _loadIngredients();
        _scrollToTop(_ingredientScrollController);
        return;
    }
  }

  void _scrollToTop(ScrollController controller) {
    if (!mounted || !controller.hasClients) return;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openFoodFilters() async {
    final result = await showDiscoverFoodFiltersSheet(
      context,
      initial: _foodFilters,
    );
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

  Future<void> _scanLocation() async {
    if (_detectingLocation) return;
    setState(() {
      _detectingLocation = true;
      _error = null;
    });

    try {
      final region = await LocationService.detectCurrentRegion();
      setState(() {
        _detectedRegion = region;
        _detectingLocation = false;
      });
      _scheduleReload();

      // Lưu vùng miền định vị được vào hồ sơ AI trên database để Trợ lý AI có thể đề xuất chính xác
      unawaited(UserAiProfileRepository().upsert(vietnamRegion: region));

      if (mounted) {
        final displayName = LocationService.getRegionDisplayName(region);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã định vị vùng hiện tại: $displayName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _detectingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (widget.isStandalone)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textDark,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
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
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Món yêu thích',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                      _scheduleReload();
                    },
                    icon: const Icon(
                      Icons.favorite_border,
                      color: AppColors.primary,
                    ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
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
                  InputChip(
                    avatar: _detectingLocation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            _detectedRegion != null
                                ? Icons.my_location
                                : Icons.location_searching,
                            size: 16,
                            color: _detectedRegion != null
                                ? AppColors.primary
                                : null,
                          ),
                    label: Text(
                      _detectedRegion != null
                          ? 'Miền ${LocationService.getRegionDisplayName(_detectedRegion!)}'
                          : 'Quét vị trí',
                    ),
                    selected: _detectedRegion != null,
                    onSelected: (selected) {
                      if (selected) {
                        _scanLocation();
                      } else {
                        setState(() => _detectedRegion = null);
                        _scheduleReload();
                      }
                    },
                    onDeleted: _detectedRegion != null
                        ? () {
                            setState(() => _detectedRegion = null);
                            _scheduleReload();
                          }
                        : null,
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
                  ActionChip(
                    avatar: const Icon(
                      Icons.medical_information_outlined,
                      size: 18,
                    ),
                    label: const Text('Dị ứng'),
                    onPressed: _openAllergies,
                  ),
                  ActionChip(
                    label: const Text('Tải lại'),
                    onPressed: _refreshing
                        ? null
                        : () => _reloadLists(checkAllergy: false),
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
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
              ),
            Expanded(
              child: _initialLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
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
      controller: _foodScrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _foods.length + (_foodTotalPages > 1 ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _foods.length) {
          return _buildPaginationBar(
            page: _foodPage,
            totalPages: _foodTotalPages,
            totalCount: _foodTotalCount,
            loading: _refreshing,
          );
        }
        final food = _foods[index];
        return Consumer<FavoriteFoodProvider>(
          builder: (context, favorites, _) => _FoodListTile(
            food: food,
            isFavorite: favorites.isFavorite(food.id),
            isFavoriteBusy: favorites.isMutating(food.id),
            onFavorite: () async {
              final result = await favorites.toggle(
                FavoriteFoodItem.fromFood(food),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: result.isSuccess
                      ? AppColors.primary
                      : Colors.red.shade700,
                ),
              );
            },
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
          ),
        );
      },
    );
  }

  Widget _buildRecipeList() {
    if (_recipesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_recipes.isEmpty) {
      return const Center(child: Text('Không có công thức phù hợp.'));
    }
    return ListView.separated(
      controller: _recipeScrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _recipes.length + (_recipeTotalPages > 1 ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _recipes.length) {
          return _buildPaginationBar(
            page: _recipePage,
            totalPages: _recipeTotalPages,
            totalCount: _recipeTotalCount,
            loading: _recipesLoading,
          );
        }
        final recipe = _recipes[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          title: Text(
            recipe.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_ingredients.isEmpty) {
      return const Center(child: Text('Không có nguyên liệu phù hợp.'));
    }
    return ListView.separated(
      controller: _ingredientScrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _ingredients.length + (_ingredientTotalPages > 1 ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _ingredients.length) {
          return _buildPaginationBar(
            page: _ingredientPage,
            totalPages: _ingredientTotalPages,
            totalCount: _ingredientTotalCount,
            loading: _ingredientsLoading,
          );
        }
        final item = _ingredients[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          title: Text(
            item.nameVi,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (item.category != null) item.category!.translatedData,
                  if (item.caloriesKcal != null)
                    '${item.caloriesKcal!.round()} kcal',
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

  Widget _buildPaginationBar({
    required int page,
    required int totalPages,
    required int totalCount,
    required bool loading,
  }) {
    return Semantics(
      label: 'Phân trang, trang $page trên $totalPages',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: !loading && page > 1
                  ? () => _goToPage(page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trang $page / $totalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '$totalCount mục',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: !loading && page < totalPages
                  ? () => _goToPage(page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodListTile extends StatelessWidget {
  const _FoodListTile({
    required this.food,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
    required this.isFavoriteBusy,
  });

  final FoodItem food;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final bool isFavoriteBusy;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      title: Text(
        food.nameVi,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (food.caloriesKcal != null)
            Text(
              '${food.caloriesKcal!.round()} kcal · ${food.proteinG?.round() ?? 0}g đạm',
            ),
          if (food.matchedAllergens.isNotEmpty)
            Text(
              'Trùng: ${food.matchedAllergens.join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AllergyRiskBadge(riskLevel: food.allergyRiskLevel),
          IconButton(
            tooltip: isFavorite
                ? 'B\u1ecf m\u00f3n kh\u1ecfi y\u00eau th\u00edch'
                : 'Th\u00eam m\u00f3n v\u00e0o y\u00eau th\u00edch',
            onPressed: isFavoriteBusy ? null : onFavorite,
            icon: isFavoriteBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : AppColors.primary,
                  ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
