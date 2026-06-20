import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rating_entry.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_entry_actions.dart';

class RatingEntryListTile extends StatelessWidget {
  final RatingEntry ratingEntry;

  const RatingEntryListTile({super.key, required this.ratingEntry});

  Widget _scorePart(BuildContext context, {required String symbol, required String text, bool emphasized = false}) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasized ? scheme.onSurface : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(symbol, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: emphasized ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final score = appRepository.entryScore(ratingEntry);

    final avgText = score == null ? "–" : "${score.weightedAvg.toStringAsFixed(1)} / 10";
    final sumText = score == null ? "–" : score.weightedSum.toStringAsFixed(1);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      titleAlignment: ListTileTitleAlignment.titleHeight,
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      leading: const Icon(RatingEntry.iconData),
      title: Text(ratingEntry.displayName),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _scorePart(context, symbol: "Ø", text: avgText, emphasized: true),
          const SizedBox(width: 16),
          _scorePart(context, symbol: "Σ", text: sumText),
        ],
      ),
      onTap: () => RatingEntryActions.editRatingEntry(context, ratingEntry: ratingEntry),
      trailing: PopupMenuButton<_RatingEntryOption>(
        onSelected: (option) async {
          switch (option) {
            case _RatingEntryOption.edit:
              await RatingEntryActions.editRatingEntry(context, ratingEntry: ratingEntry);
            case _RatingEntryOption.remove:
              await RatingEntryActions.removeRatingEntry(context, ratingEntry: ratingEntry);
          }
        },
        itemBuilder: (BuildContext context) => _RatingEntryOption.values.map((option) {
          return PopupMenuItem<_RatingEntryOption>(
            value: option,
            child: Row(
              spacing: 10,
              children: [
                Icon(option.iconData, size: 20),
                Text(option.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _RatingEntryOption {
  edit("Edit", Icons.edit),
  remove("Remove", Icons.delete);

  final String label;
  final IconData iconData;
  const _RatingEntryOption(this.label, this.iconData);
}
