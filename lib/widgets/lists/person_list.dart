import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../utils/person_actions.dart';
import '../chips/person_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../items/person_list_card.dart';

class PersonList extends StatelessWidget {
  const PersonList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: PersonListFilterWidget()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
              icon: Person.iconData,
              title: 'No profile yet',
              subtitle: 'Add a rider profile to link to your setups.',
              actionLabel: 'Add a profile',
              onAction: () => PersonActions.addPerson(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final personsList = appRepository.filteredPersons.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PersonListCard(
                person: personsList[index],
                index: index,
                elevation: elevation,
              ),
            ),
          );
        },
        child: child,
      );
    }

    return personsList.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: personsList.length,
            padding: const EdgeInsets.only(bottom: 16+100),
            header: const PersonListFilterWidget(),
            proxyDecorator: proxyDecorator,
            onReorderStart: (_) => unawaited(HapticFeedback.lightImpact()),
            onReorderItem: (int oldIndex, int newIndex) => PersonActions.onReorderPerson(context, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final person = personsList[index];
              return Padding(
                key: ValueKey(person.id),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PersonListCard(
                  person: person,
                  index: index,
                ),
              );
            },
          );
  }
}
