import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';
import '../chips/bike_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/app_hint_slot.dart';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _scrollDelta = 0;

  static const double _edgeZone = 100.0;
  static const double _maxScrollSpeed = 18.0;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _draggedComponentNotifier.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_draggedComponentNotifier.value == null) {
      _stopEdgeScroll();
      return;
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final dy = event.position.dy;

    if (dy < _edgeZone) {
      _scrollDelta = -_maxScrollSpeed * (1 - dy / _edgeZone);
    } else if (dy > screenHeight - _edgeZone) {
      _scrollDelta = _maxScrollSpeed * (1 - (screenHeight - dy) / _edgeZone);
    } else {
      _stopEdgeScroll();
      return;
    }

    _scrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients || _scrollController.positions.length != 1) return;
      final pos = _scrollController.position;
      final next = (pos.pixels + _scrollDelta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      _scrollController.jumpTo(next);
    });
  }

  void _stopEdgeScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _scrollDelta = 0;
  }

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
          // → uninstalled
          if (isSimple) {
            // Single-entry mode: swap the Archival for a Uninstallation.
            final now = DateTime.now();
            await appRepository.editComponent(
              component.copyWith(
                installations: [
                Uninstallation(dateTimeUTC: now.toUtc(), dateTimeLocal: now, componentId: component.id),
                ],
              ),
            );
          } else if (unarchived.bike != null) {
            // Timeline: was on a bike before archiving — open sheet to confirm uninstall date.
            unawaited(showAddInstallationSheet(context, component: unarchived, targetBikeId: null));
          } else {
            // Timeline: was already uninstalled before archiving — just drop the Archival.
            await appRepository.editComponent(unarchived);
          }
        } else {
          // → bike
          final hasHistory = unarchived.installations.length > 1 ||
              (unarchived.installations.isNotEmpty &&
                  unarchived.installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);
          if (!isSimple || hasHistory) {
            unawaited(showAddInstallationSheet(context, component: unarchived, targetBikeId: newBike));
          } else {
            await appRepository.editComponent(unarchived.copyWithNewInstallation(newBike));
          }
        }

        _draggedComponentNotifier.value = null;
        return;
      }

      // Standard (non-archived) install / uninstall flow.
      final isComplexInstallation = component.installations.length > 1 ||
          (component.installations.isNotEmpty && component.installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);
      if (appSettings.enableInstallationTimeline || isComplexInstallation) {
        unawaited(showAddInstallationSheet(context, component: component, targetBikeId: newBike));
      } else {
        await appRepository.editComponent(component.copyWithNewInstallation(newBike));
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
        unawaited(showAddInstallationSheet(context, component: component, targetBikeId: null, isArchiving: true));
      } else {
        await appRepository.editComponent(
          component.copyWith(
            installations: [
              Archival(
                componentId: component.id,
                dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0),
              ),
            ],
          ),
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
      _componentToShowDetails = _componentToShowDetails == component.id ? null : component.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
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
        : Listener(
            onPointerMove: _onPointerMove,
            onPointerUp: (_) => _stopEdgeScroll(),
            onPointerCancel: (_) => _stopEdgeScroll(),
            child: ReorderableListView.builder(
              scrollController: _scrollController,
              itemCount: bikesList.length,
              padding: const EdgeInsets.only(
                left: 16,
                top: 16,
                right: 16,
                bottom: 16 + 100,
              ),
              header: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  GettingStartedGuideHint(),
                  AppHintSlot(placement: AppHintPlacement.garageHeader),
                  BikeListFilterWidget(),
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
              onReorderStart: (_) => unawaited(HapticFeedback.lightImpact()),
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
            ),
          );
  }
}
