import 'package:flutter/material.dart';
import '../models/setting.dart';

class SettingList extends StatelessWidget {
  final List<Setting> settings;

  const SettingList({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: settings.length,
      itemBuilder: (context, index) {
        final setting = settings[index];
        return ListTile(
          title: Text('Setting: ${setting.name}'),
        );
      },
    );
  }
}