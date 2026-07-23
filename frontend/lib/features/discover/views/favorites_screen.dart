import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';
import 'food_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repository = FoodDiscoveryRepository();
  List<FavoriteFoodItem> _items = [];
  final Set<String> _removingIds = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repository.getFavorites();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _removeFavorite(FavoriteFoodItem item) async {
    if (_removingIds.contains(item.foodId)) return;
    setState(() => _removingIds.add(item.foodId));

    final ok = await _repository.removeFavorite(item.foodId);
    if (!mounted) return;
    setState(() {
      _removingIds.remove(item.foodId);
      if (ok) {
        _items.removeWhere((favorite) => favorite.foodId == item.foodId);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã bỏ ${item.nameVi} khỏi mục yêu thích' : 'Không thể bỏ món yêu thích. Vui lòng thử lại.'),
        backgroundColor: ok ? null : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Món yêu thích'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
          ? const Center(child: Text('Chưa có món yêu thích.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.nameVi),
                  subtitle: item.caloriesKcal != null ? Text('${item.caloriesKcal!.round()} kcal') : null,
                  trailing: IconButton(
                    tooltip: 'Bỏ khỏi mục yêu thích',
                    icon: _removingIds.contains(item.foodId)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.favorite, color: Colors.red),
                    onPressed: _removingIds.contains(item.foodId) ? null : () => _removeFavorite(item),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: item.foodId)),
                    ).then((_) => _load());
                  },
                );
              },
            ),
    );
  }
}
