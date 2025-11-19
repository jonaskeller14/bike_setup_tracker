import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/setting.dart';
import '../widgets/adjustment_display_list.dart';

class SettingList extends StatefulWidget {
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
  State<SettingList> createState() => _SettingListState();
}

class _SettingListState extends State<SettingList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded
        ? widget.settings.length
        : widget.settings.length.clamp(0, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCount,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, index) {
            final setting = widget.settings[widget.settings.length - 1 - index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  setting.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(setting.datetime),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (setting.place != null)
                      Text(
                        "${setting.place?.thoroughfare} ${setting.place?.subThoroughfare}, "
                        "${setting.place?.locality}, ${setting.place?.country}",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (setting.position != null)
                      Text(
                        "↑ Altitude: ${setting.position!.altitude!.round()} m",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    if (setting.temperature != null)
                      Text(
                        "${setting.temperature!.toStringAsFixed(1)} °C",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    if (setting.notes != null && setting.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        setting.notes!,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 6.0),
                    AdjustmentDisplayList(
                      adjustmentValues: setting.adjustmentValues,
                      previousAdjustmentValues:
                          setting.previousSetting?.adjustmentValues,
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.editSetting(setting);
                    } else if (value == 'remove') {
                      widget.removeSetting(setting);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20),
                          SizedBox(width: 10),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (widget.settings.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(_expanded ? "Show less" : "Show more"),
            ),
          ),
      ],
    );
  }
}
