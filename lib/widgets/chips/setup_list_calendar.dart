import 'package:flutter/material.dart';

import '../../pages/calendar_page.dart';
import '../../utils/automation_ids.dart';

class SetupListCalendar extends StatelessWidget {
  const SetupListCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: AutomationIds.setupListCalendar,
      child: FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: const SizedBox.shrink(),
        labelPadding: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.zero,
        avatar: const Icon(Icons.calendar_month_outlined),
        showCheckmark: false,
        selected: false,
        onSelected: (_) async {
          await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
        },
      ),
    );
  }
}
