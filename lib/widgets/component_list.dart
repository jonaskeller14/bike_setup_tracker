import 'package:flutter/material.dart';
import '../models/component.dart';

class ComponentList extends StatelessWidget {
  final List<Component> components;

  const ComponentList({super.key, required this.components});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        return ListTile(
          title: Text('Component: ${component.name}'),
        );
      },
    );
  }
}