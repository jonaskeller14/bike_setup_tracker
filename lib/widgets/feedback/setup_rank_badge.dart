import 'package:flutter/material.dart';

import '../../services/feedback_ranking_service.dart';
import '../items/tile_meta_row.dart';

/// "2/7 compared": where the setup ranks among the setups of its bike that took
/// part in a comparison. A muted metadata row like tags, since the rank is an
/// estimate; only the top three are bold. Callers show it only while the rank
/// is confident.
class SetupRankBadge extends StatelessWidget {
  static const int highlightedRanks = 3;

  final SetupRank rank;

  const SetupRankBadge({super.key, required this.rank});

  static String label(SetupRank rank) => '${rank.rank}/${rank.of} compared';

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Estimated rank among the ${rank.of} setups of this bike you compared in feedback',
      child: TileMetaRow(
        icon: Icons.leaderboard,
        text: label(rank),
        muted: true,
        bold: rank.rank <= highlightedRanks,
      ),
    );
  }
}
