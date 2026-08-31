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
import '../../services/app_hint_service.dart';
import '../../utils/bike_actions.dart';
import '../../utils/installation_timeline_validation.dart';
import '../chips/bike_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/app_hint_slot.dart';
import '../items/garage_bike_card.dart';
import '../items/garage_uninstalled_card.dart';
import '../sheets/installation_sheet.dart';
import '../sheets/installation_timeline_hint_sheet.dart';
import 'list_scroll_controller.dart';

class GarageList extends StatefulWidget {
  final ListScrollController controller;

  const GarageList({super.key, required this.controller});

  @override
  State<GarageList> createState() => _GarageListState();
}

class _GarageListState extends State<GarageList> {
  String? _componentToShowDetails;
  final ValueNotifier<Component?> _draggedComponentNotifier = ValueNotifier<Component?>(null);
  Timer? _scrollTimer;
  double _scrollDelta = 0;

  static const double _edgeZone = 100.0;
  static const double _maxScrollSpeed = 18.0;

  @override
  void dispose() {
    _scrollTimer?.cancel();
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
      if (!widget.controller.scrollController.hasClients || widget.controller.scrollController.positions.length != 1) return;
      final pos = widget.controller.scrollController.position;
      final next = (pos.pixels + _scrollDelta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      widget.controller.scrollController.jumpTo(next);
    });
  }

  void _stopEdgeScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _scrollDelta = 0;
  }

  Future<void> _offerInstallationTimeline(Component component) async {
    final appSettings = context.read<AppSettings>();
    final hintService = context.read<AppHintService>();
    if (!hintService.shouldOfferInstallationTimeline(component.installations)) {
      return;
    }

    final activate = await showInstallationTimelineHintSheet(
      context,
      component: component,
    );
    if (!mounted) return;

    if (activate) {
      appSettings.enableInstallationTimeline = true;
      await hintService.complete(AppHint.installationTimelineV1);
    } else {
      await hintService.dismiss(AppHint.installationTimelineV1);
    }
  }

  void _onAcceptWithDetails({String? newBike}) async {
    if (_draggedComponentNotifier.value == null) return;
    final component = _draggedComponentNotifier.value!;
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();

    await Future.microtask(() async {
      if (!mounted) return;
      await _offerInstallationTimeline(component);
      if (!mounted) return;

      if (component.isArchived) {
        final isSimple = !shouldUseInstallationTimeline(
          featureEnabled: appSettings.enableInstallationTimeline,
          installations: component.installations,
        );

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
          final hasHistory = isComplexInstallationTimeline(unarchived.installations);
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
      if (shouldUseInstallationTimeline(
        featureEnabled: appSettings.enableInstallationTimeline,
        installations: component.installations,
      )) {
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
      await _offerInstallationTimeline(component);
      if (!mounted) return;
      if (shouldUseInstallationTimeline(
        featureEnabled: appSettings.enableInstallationTimeline,
        installations: component.installations,
      )) {
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
    return CustomScrollView(
      controller: widget.controller.scrollController,
      slivers: [
        const SliverToBoxAdapter(
          child: AppHintSlot(
            placement: AppHintPlacement.garageHeader,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              scrollController: widget.controller.scrollController,
              itemCount: bikesList.length,
              padding: const EdgeInsets.only(
                left: 16,
                top: 8,
                right: 16,
                bottom: 16 + 100,
              ),
              header: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHintSlot(
                    placement: AppHintPlacement.garageHeader,
                    padding: EdgeInsetsGeometry.only(bottom: 8)),
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
              onReorderItem: (int oldIndex, int newIndex) =>
                  BikeActions.onReorderBikes(context, oldIndex: oldIndex, newIndex: newIndex),
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
