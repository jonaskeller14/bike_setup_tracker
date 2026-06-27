import 'package:collection/collection.dart';

enum TipProduct {
  small(
    label: 'Buy me a coffee',
    emoji: '☕',
    fallbackPrice: '€0.99',
    productId: 'tipcoffee',
  ),
  medium(
    label: 'Buy me a snack',
    emoji: '🥪',
    fallbackPrice: '€2.99',
    productId: 'tipsnack',
  ),
  large(
    label: 'Buy me a meal',
    emoji: '🍕',
    fallbackPrice: '€5.99',
    productId: 'tipmeal',
  );

  const TipProduct({
    required this.label,
    required this.emoji,
    required this.fallbackPrice,
    required this.productId,
  });

  final String label;
  final String emoji;
  final String fallbackPrice;
  final String productId;

  static bool isTipProductId(String id) => values.any((t) => t.productId == id);

  static TipProduct? fromProductId(String id) => values.firstWhereOrNull((t) => t.productId == id);
}
