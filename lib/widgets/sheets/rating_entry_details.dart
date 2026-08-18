import 'package:flutter/material.dart';

import '../../models/rating_entry.dart';
import '../../pages/details/rating_entry_details_page.dart';

Future<void> showRatingEntryDetailsSheet({required BuildContext context, required RatingEntry ratingEntry}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: RatingEntryDetailsContent(
        ratingEntryId: ratingEntry.id,
        showEditButton: true,
        showCloseButton: true,
      ),
    ),
  );
}
