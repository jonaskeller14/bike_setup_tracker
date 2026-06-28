import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';
import '../chips/bike_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/garage_list_hint.dart';
import '../hints/getting_started_guide_hint.dart';
import '../items/garage_bike_card.dart';
import '../items/garage_uninstalled_card.dart';
import '../sheets/installation_sheet.dart';

class GarageList extends StatefulWidget {
  const GarageList({super.key});

  @override
  State<GarageList> createState() => _GarageListState();
}

class _GarageListState extends State<GarageList> {
  String? _componentToShowDetails;
  final ValueNotifier<Component?> _draggedComponentNotifier = ValueNotifier<Component?>(null);

  void _onAcceptWithDetails({String? newBike}) async {
    if (_draggedComponentNotifier.value == null) return;
    final component = _draggedComponentNotifier.value!;
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();

    await Future.microtask(() async {
      if (!mounted) return;

      if (component.isArchived) {
        final isSimple = !appSettings.enableInstallationTimeline;

        // Strip the trailing Archival to recover the pre-archive state.
        final unarchived = component.copyWith(
          installations: List<Installation>.from(component.installations)
            ..removeAt(component.installations.lastIndexWhere((i) => i is Archival)),
        );

        if (newBike == null) {
          // → deinstalled
          if (isSimple) {
            // Single-entry mode: swap the Archival for a Deinstallation.
            final now = DateTime.now();
            await appRepository.editComponent(
              component.copyWith(installations: [
                Deinstallation(dateTimeUTC: now.toUtc(), dateTimeLocal: now, componentId: component.id),
              ]),
            );
          } else if (unarchived.bike != null) {
            // Timeline: was on a bike before archiving — open sheet to confirm deinstall date.
            showAddInstallationSheet(context, component: unarchived, targetBikeId: null);
          } else {
            // Timeline: was already deinstalled before archiving — just drop the Archival.
            await appRepository.editComponent(unarchived);
          }
        } else {
          // → bike
          final hasHistory = unarchived.installations.length > 1 ||
              (unarchived.installations.isNotEmpty &&
                  unarchived.installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);
          if (!isSimple || hasHistory) {
            showAddInstallationSheet(context, component: unarchived, targetBikeId: newBike);
          } else {
            await appRepository.editComponent(unarchived.copyWithNewInstallation(newBike));
          }
        }

        _draggedComponentNotifier.value = null;
        return;
      }

      // Standard (non-archived) install / deinstall flow.
      final isComplexInstallation = component.installations.length > 1 ||
          (component.installations.isNotEmpty && component.installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);
      if (appSettings.enableInstallationTimeline || isComplexInstallation) {
        showAddInstallationSheet(context, component: component, targetBikeId: newBike);
      } else {
        appRepository.editComponent(component.copyWithNewInstallation(newBike));
      }
      _draggedComponentNotifier.value = null;
    });
  }

  void _onArchiveAccept() async {
    if (_draggedComponentNotifier.value == null) return;
    final component = _draggedComponentNotifier.value!;
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();

    await Future.microtask(() async {
      if (!mounted) return;
      if (appSettings.enableInstallationTimeline) {
        showAddInstallationSheet(context, component: component, targetBikeId: null, isArchiving: true);
      } else {
        final now = DateTime.now();
        await appRepository.editComponent(
          component.copyWith(installations: [
            Archival(
              componentId: component.id,
              dateTimeUTC: now.toUtc(),
              dateTimeLocal: now,
            ),
          ]),
        );
      }
      _draggedComponentNotifier.value = null;
    });
  }

  Widget _emptyPlaceholder(BuildContext context) {
    final showGuide = context.watch<AppSettings>().showGettingStartedGuideHint;
    if (showGuide) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BikeListFilterWidget(),
            SizedBox(height: 8),
            GettingStartedGuideHint(),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: BikeListFilterWidget()),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
              icon: Bike.iconData,
              title: 'No bikes yet',
              subtitle: 'Add your first bike to get started.',
              actionLabel: 'Add a bike',
              onAction: () => BikeActions.addBike(context),
            ),
          ),
        ),
      ],
    );
  }

  void _onPressedComponent(Component component) {
    setState(() {
      _componentToShowDetails = _componentToShowDetails == component.id
          ? null
          : component.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final bikesList = appRepository.filteredBikes.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: GarageBikeCard(
              bike: bikesList[index],
              index: index,
              elevation: elevation,
              componentToShowDetails: _componentToShowDetails,
              onPressedComponent: _onPressedComponent,
              onAcceptWithDetails: _onAcceptWithDetails,
              setDraggedComponent: (Component? c) => _draggedComponentNotifier.value = c,
              draggedComponentNotifier: _draggedComponentNotifier,
            ),
          );
        },
        child: child,
      );
    }

    return bikesList.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: bikesList.length,
            padding: const EdgeInsets.only(
              left: 16,
              top: 16,
              right: 16,
              bottom: 16 + 100,
            ),
            header: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const GettingStartedGuideHint(),
                if (appRepository.bikes.length >= 2 &&
                    appRepository.components.isNotEmpty &&
                    appSettings.showGarageListHint &&
                    !appSettings.hintShownThisSession)
                  const GarageListHint(),
                const BikeListFilterWidget(),
              ],
            ),
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 50),
                GarageUninstalledCard(
                  componentToShowDetails: _componentToShowDetails,
                  onPressedComponent: _onPressedComponent,
                  onAcceptWithDetails: _onAcceptWithDetails,
                  onArchiveAccept: _onArchiveAccept,
                  setDraggedComponent: (Component? c) => _draggedComponentNotifier.value = c,
                  draggedComponentNotifier: _draggedComponentNotifier,
                ),
              ],
            ),
            proxyDecorator: proxyDecorator,
            onReorderItem: (int oldIndex, int newIndex) => BikeActions.onReorderBikes(context, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final bike = bikesList[index];
              return GarageBikeCard(
                key: ValueKey(bike.id),
                bike: bike,
                index: index,
                componentToShowDetails: _componentToShowDetails,
                onPressedComponent: _onPressedComponent,
                onAcceptWithDetails: _onAcceptWithDetails,
                setDraggedComponent: (Component? c) => _draggedComponentNotifier.value = c,
                draggedComponentNotifier: _draggedComponentNotifier,
              );
            },
          );
  }
}
