import 'package:flutter/material.dart';

import 'bike_and_priority_filter.dart';

class TaskListFilterWidget extends StatelessWidget {
  const TaskListFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          BikeAndPriorityFilterChip(),
        ],
      ),
    );
  }
}
