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
                      subtitle: item.caloriesKcal != null
                          ? Text('${item.caloriesKcal!.round()} kcal')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _repository.removeFavorite(item.foodId);
                          _load();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodDetailScreen(foodId: item.foodId),
                          ),
                        ).then((_) => _load());
                      },
                    );
                  },
                ),
    );
  }
}
