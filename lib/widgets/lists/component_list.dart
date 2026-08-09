import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/component.dart';
import '../../repositories/app_repository.dart';
import '../../utils/component_actions.dart';
import '../chips/component_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../items/component_list_card.dart';

class ComponentList extends StatelessWidget {
  const ComponentList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: ComponentListFilterWidget()),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
              icon: Component.iconData,
              title: 'No components yet',
              subtitle: 'Add your first component to track its settings.',
              actionLabel: 'Add a component',
              onAction: () => ComponentActions.addComponent(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final componentsList = appRepository.filteredComponents.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: ComponentListCard(
              component: componentsList[index],
              index: index,
              elevation: elevation,
            ),
          );
        },
        child: child,
      );
    }

    return componentsList.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: componentsList.length,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: const ComponentListFilterWidget(),
            proxyDecorator: proxyDecorator,
            onReorderStart: (_) => unawaited(HapticFeedback.lightImpact()),
            onReorderItem: (int oldIndex, int newIndex) => ComponentActions.onReorderComponents(context, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final component = componentsList[index];
              return ComponentListCard(
                key: ValueKey(component.id),
                component: component,
                index: index,
              );
            },
          );
  }
}
