import 'package:flutter/material.dart';

class SettingList extends StatelessWidget {
  final List<String> settings;

  const SettingList({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: settings.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Setting: ${settings[index]}'),
        );
      },
    );
  }
}