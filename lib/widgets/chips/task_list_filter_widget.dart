import 'package:flutter/material.dart';
import 'bike_and_tags_filter.dart';

class TaskListFilterWidget extends StatelessWidget {
  const TaskListFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          BikeAndTagsFilterChip(enableSetupTagFilter: false),
        ],
      ),
    );
  }
}
