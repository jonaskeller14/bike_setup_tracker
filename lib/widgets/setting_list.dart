import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/setting.dart';

class SettingList extends StatelessWidget {
  final List<Setting> settings;
  final void Function(Setting setting) editSetting;
  final void Function(Setting setting) removeSetting;

  const SettingList({
    super.key,
    required this.settings,
    required this.editSetting,
    required this.removeSetting,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: settings.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final setting = settings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              setting.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(setting.datetime),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  editSetting(setting);
                } else if (value == 'remove') {
                  removeSetting(setting);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text('Remove'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
