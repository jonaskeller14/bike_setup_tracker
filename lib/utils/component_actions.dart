import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../pages/component_page.dart';
import '../repositories/app_repository.dart';
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

  static Future<void> removeComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.removeComponents([component]);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Component '${component.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => await appRepository.restoreComponents([component]),
      ),
    ));
  }

  static Future<void> onReorderComponents(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    appRepository.reorderComponent(oldIndex: oldIndex, newIndex: newIndex, filteredComponentsList: appRepository.filteredComponents.values.toList());
  }
}

class _Sentinel {
  const _Sentinel();
}
