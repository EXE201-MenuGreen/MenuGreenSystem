import 'package:flutter/material.dart';

import '../models/food_models.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFavorite,
  });

  final RecommendationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChip(
                          '${item.caloriesKcal.round()} kcal',
                          Colors.orange,
                        ),
                        _buildChip(
                          'P ${item.proteinG.round()}g',
                          Colors.red,
                        ),
                        _buildChip(
                          'C ${item.carbsG.round()}g',
                          Colors.blue,
                        ),
                        _buildChip(
                          'F ${item.fatG.round()}g',
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.displayTimeMin > 0) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.displayTimeMin} phút',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (item.estimatedPriceVnd > 0) ...[
                          if (item.displayTimeMin > 0) const SizedBox(width: 12),
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          Text(
                            _formatPrice(item.estimatedPriceVnd),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.matchReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.matchReason!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                    if (item.hasAllergyWarning) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.matchedAllergens.isEmpty
                            ? 'Cần kiểm tra thông tin dị ứng'
                            : 'Dị ứng: ${item.matchedAllergens.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  if (item.score > 0) ...[
                    _buildScoreBadge(),
                    const SizedBox(height: 8),
                  ],
                  if (onFavorite != null)
                    IconButton(
                      onPressed: onFavorite,
                      icon: const Icon(Icons.favorite_border, size: 20),
                      color: Colors.grey,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final color = item.isFood ? Colors.blue : Colors.orange;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.isFood ? Icons.restaurant : Icons.menu_book,
        color: color,
        size: 28,
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildScoreBadge() {
    final score = item.score;
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '${(score * 100).round()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'điểm',
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return '$price';
  }
}
