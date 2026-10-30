import 'package:collection/collection.dart';

enum TipProduct {
  small(
    emoji: '☕',
    productId: 'tipcoffee',
  ),
  medium(
    emoji: '🥪',
    productId: 'tipsnack',
  ),
  large(
    emoji: '🍕',
    productId: 'tipmeal',
  );

  const TipProduct({
    required this.emoji,
    required this.productId,
  });

  final String emoji;
  final String productId;

  static bool isTipProductId(String id) => values.any((t) => t.productId == id);

  static TipProduct? fromProductId(String id) => values.firstWhereOrNull((t) => t.productId == id);
}
