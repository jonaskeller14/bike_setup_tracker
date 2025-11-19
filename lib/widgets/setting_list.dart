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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: setting.isCurrent
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 8, 8), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(0.0),
                      title: Text(
                        setting.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(setting.datetime),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
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
                    if (setting.notes != null && setting.notes!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3), // tweak to match font size
                            child: Icon(
                              Icons.notes,
                              size: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              setting.notes!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.pedal_bike, size: 13, color: Colors.grey.shade800),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            setting.bike.name,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (setting.place != null) ... [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.location_pin, size: 13, color: Colors.grey.shade800),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              "${setting.place?.thoroughfare} ${setting.place?.subThoroughfare}, ${setting.place?.locality}, ${setting.place?.isoCountryCode}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 4,
                      children: [
                        if (setting.position != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setting.position!.altitude!.round()} m",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                        if (setting.temperature != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.thermostat, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setting.temperature!.toStringAsFixed(1)} °C",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                      ],
                    ),
                    AdjustmentDisplayList(
                      adjustmentValues: setting.adjustmentValues,
                      previousAdjustmentValues: setting.previousSetting?.adjustmentValues,
                    ),
                  ]
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
