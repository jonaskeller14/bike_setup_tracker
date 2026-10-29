import 'package:flutter/material.dart';

import '../../pages/details/feedback_details_page.dart';

Future<void> showFeedbackDetailsSheet({
  required BuildContext context,
  required String feedbackId,
  bool showViewOnMap = true,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: FeedbackDetailsContent(
        feedbackId: feedbackId,
        showEditButton: true,
        showCloseButton: true,
        showViewOnMap: showViewOnMap,
      ),
    ),
  );
}
