import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/discover/models/food_models.dart';
import 'package:frontend/features/discover/providers/favorite_food_provider.dart';
import 'package:frontend/features/discover/repositories/food_discovery_repository.dart';

FavoriteFoodItem _food(String id, {String name = 'Bún bò'}) {
  return FavoriteFoodItem(
    foodId: id,
    nameVi: name,
    caloriesKcal: 420,
    proteinG: 28,
  );
}

void main() {
  group('FavoriteFoodProvider', () {
    test('loads server favorites as the shared source of truth', () async {
      final provider = FavoriteFoodProvider(
        fetchFavorites: () async => FavoriteFoodsLoadResult(
          items: [_food('food-1')],
          isFromCache: false,
        ),
      );

      await provider.load();

      expect(provider.items, hasLength(1));
      expect(provider.isFavorite('food-1'), isTrue);
      expect(provider.isFromCache, isFalse);
    });

    test('keeps optimistic favorite when backend confirms the add', () async {
      var cacheWrites = 0;
      final provider = FavoriteFoodProvider(
        addFavorite: (id) async => FavoriteFoodMutationResult.success(
          isFavorite: true,
          item: _food(id),
          message: 'Đã thêm món vào yêu thích.',
        ),
        cacheFavorites: (_) async => cacheWrites++,
      );

      final result = await provider.toggle(_food('food-2'));

      expect(result.isSuccess, isTrue);
      expect(result.isFavorite, isTrue);
      expect(provider.isFavorite('food-2'), isTrue);
      expect(cacheWrites, 1);
    });

    test('rolls back optimistic state when backend rejects the add', () async {
      final provider = FavoriteFoodProvider(
        addFavorite: (_) async => const FavoriteFoodMutationResult.failure(
          message: 'Không thể thêm món vào yêu thích.',
        ),
      );

      final result = await provider.toggle(_food('food-3'));

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Không thể thêm món vào yêu thích.');
      expect(provider.isFavorite('food-3'), isFalse);
      expect(provider.items, isEmpty);
    });
  });
}
