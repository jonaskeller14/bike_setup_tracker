import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../pages/adjustment/boolean_adjustment_page.dart';
import '../pages/adjustment/categorical_adjustment_page.dart';
import '../pages/adjustment/duration_adjustment_page.dart';
import '../pages/adjustment/numerical_adjustment_page.dart';
import '../pages/adjustment/step_adjustment_page.dart';
import '../pages/adjustment/text_adjustment_page.dart';
import '../pages/component_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/sheets/component_add_adjustment.dart';
import '../widgets/sheets/replace_component.dart';
import 'bike_actions.dart';

class ComponentActions {
  static Future<void> addComponent(BuildContext context, {Object? initialBike = const _Sentinel()}) async {
    final appRepository = context.read<AppRepository>();

    late Component? component;
    if (initialBike is _Sentinel) {
      if (appRepository.filteredBikes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          content: Text("Add a bike first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          action: SnackBarAction(
            label: 'ADD',
            textColor: Theme.of(context).colorScheme.onErrorContainer,
            onPressed: () => BikeActions.addBike(context),
          ),
        ));
        return;
      }
      component = await Navigator.push<Component>(
        context,
        MaterialPageRoute(builder: (context) => ComponentPage.add()),
      );
    } else {
      component = await Navigator.push<Component>(
        context,
        MaterialPageRoute(builder: (context) => ComponentPage.add(initialBike: initialBike as String?)),
      );
    }
    
    if (component == null) return;
    await appRepository.addComponent(component);
  }

  static Future<void> editComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();

    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.edit(component: component),
      ),
    );
    if (editedComponent == null) return;
    await appRepository.editComponent(editedComponent);
  }

  static Future<void> duplicateComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();

    final newComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.duplicate(component: component.deepCopy()),
      ),
    );
    if (newComponent == null) return;

    await appRepository.addComponent(newComponent);
  }

  static Future<void> replaceComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();

    final replacementDate = await showReplaceComponentSheet(context, component: component);
    if (replacementDate == null) return;
    
    if (!context.mounted) return;
    final newComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.replace(
          component: component.deepCopy(),
          replacementDate: replacementDate,
        ),
      ),
    );
    if (newComponent == null) return;

    await appRepository.addComponent(newComponent);
    await appRepository.editComponent(component.copyWith(installations: [
      ...component.installations, 
      Installation(parent: null, dateTimeUTC: replacementDate.toUtc(), dateTimeLocal: replacementDate.toLocal())
    ]));
  } 

  static Future<void> removeComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.removeComponents([component]);

    messenger.showSnackBar(SnackBar(
      content: Text("Component '${component.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.restoreComponents([component]),
      ),
    ));
  }

  static Future<void> restoreComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreComponents([component]);

    messenger.showSnackBar(SnackBar(
      content: Text("Component '${component.name}' restored from trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.removeComponents([component]),
      ),
    ));
  }

  static Future<void> onReorderComponents(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderComponent(oldIndex: oldIndex, newIndex: newIndex, filteredComponentsList: appRepository.filteredComponents.values.toList());
  }

  static Future<void> addAdjustmentForComponent(BuildContext context, {required Component component}) async {
    showComponentAddAdjustmentBottomSheet(
      context: context,
      componentType: component.componentType,
      enableDurationAdjustment: false,
      addAdjustmentFromPreset: (Adjustment adjustment) async {
        final appRepository = context.read<AppRepository>();
        final newAdjustment = await Navigator.push<Adjustment>(
          context,
          MaterialPageRoute(builder: (context) => switch (adjustment.deepCopy()) {
            final BooleanAdjustment a     => BooleanAdjustmentPage.template(adjustment: a),
            final CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a),
            final StepAdjustment a        => StepAdjustmentPage.template(adjustment: a),
            final NumericalAdjustment a   => NumericalAdjustmentPage.template(adjustment: a),
            final TextAdjustment a        => TextAdjustmentPage.template(adjustment: a),
            final DurationAdjustment a    => DurationAdjustmentPage.template(adjustment: a),
          }),
        );
        if (newAdjustment == null) return;
        await appRepository.editComponent(component.copyWith(adjustments: [...component.adjustments, newAdjustment]));
      },
      addAdjustment: <T extends Adjustment>() async {
        final appRepository = context.read<AppRepository>();
        final newAdjustment = await Navigator.push<T>(
          context,
          MaterialPageRoute(builder: (context) => switch(T) {
            const (BooleanAdjustment)       => BooleanAdjustmentPage.add(),
            const (CategoricalAdjustment)   => CategoricalAdjustmentPage.add(),
            const (StepAdjustment)          => StepAdjustmentPage.add(),
            const (NumericalAdjustment)     => NumericalAdjustmentPage.add(),
            const (TextAdjustment)          => TextAdjustmentPage.add(),
            const (DurationAdjustment)      => DurationAdjustmentPage.add(),
            Type() => throw UnimplementedError(),
          }),
        );
        if (newAdjustment == null) return;
        await appRepository.editComponent(component.copyWith(adjustments: [...component.adjustments, newAdjustment]));
      },
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
