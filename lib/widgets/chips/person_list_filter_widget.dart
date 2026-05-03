import 'package:flutter/material.dart';
import 'bike_and_tags_filter.dart';

class PersonListFilterWidget extends StatelessWidget {
  const PersonListFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 8),
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
