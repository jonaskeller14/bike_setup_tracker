import 'package:flutter/material.dart';

import '../../models/feedback/test_session.dart';
import 'test_session_tile.dart';

class TestSessionScopeCard extends StatelessWidget {
  final TestSession session;
  final String explanation;

  const TestSessionScopeCard({super.key, required this.session, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The form already acts on the session, so its menu stays out.
          TestSessionTile(session: session, showOptionsMenu: false),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              explanation,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
