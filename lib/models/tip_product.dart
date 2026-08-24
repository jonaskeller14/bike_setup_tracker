import 'package:collection/collection.dart';

enum TipProduct {
  small(
    label: 'Buy me a coffee',
    emoji: '☕',
    productId: 'tipcoffee',
  ),
  medium(
    label: 'Buy me a snack',
    emoji: '🥪',
    productId: 'tipsnack',
  ),
  large(
    label: 'Buy me a meal',
    emoji: '🍕',
    productId: 'tipmeal',
  );

  const TipProduct({
    required this.label,
    required this.emoji,
    required this.productId,
  });

  final String label;
  final String emoji;
  final String productId;

  static bool isTipProductId(String id) => values.any((t) => t.productId == id);

  static TipProduct? fromProductId(String id) => values.firstWhereOrNull((t) => t.productId == id);
}
