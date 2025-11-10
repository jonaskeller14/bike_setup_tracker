import 'package:flutter/material.dart';

class ComponentList extends StatelessWidget {
  final List<String> components;

  const ComponentList({super.key, required this.components});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: components.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Component: ${components[index]}'),
        );
      },
    );
  }
}