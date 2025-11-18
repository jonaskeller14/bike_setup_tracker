import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/bike.dart';
import '../models/setting.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import '../widgets/adjustment_set_list.dart';

class EditSettingPage extends StatefulWidget {
  final Setting setting;
  final List<Component> components;
  final List<Bike> bikes;

  const EditSettingPage({super.key, required this.setting, required this.components, required this.bikes});

  @override
  State<EditSettingPage> createState() => _EditSettingPageState();
}

class _EditSettingPageState extends State<EditSettingPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late Bike bike;
  List<Component> bikeComponents = [];
  late DateTime _selectedDateTime;
  Map<Adjustment, dynamic> adjustmentValues = {};

  late LocationData? _currentLocation;

  late geo.Placemark? _currentPlace;

  late double? temperature;

  @override
  void initState() {
    super.initState();
    bike = widget.setting.bike;
    onBikeChange();

    // Initialize with existing setting values
    _nameController = TextEditingController(text: widget.setting.name);
    _notesController = TextEditingController(text: widget.setting.notes ?? '');
    _selectedDateTime = widget.setting.datetime;
    _currentLocation = widget.setting.position;
    _currentPlace = widget.setting.place;
    temperature = widget.setting.temperature;
  }

  void onBikeChange () {
    bikeComponents = widget.components.where((c) => c.bike == bike).toList();

    // Set initial values by reading currentSetting
    adjustmentValues.clear();
    if (widget.setting.bike == bike) {
      for (final adjustmentValue in widget.setting.adjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
      }
    } else {
      for (final component in bikeComponents) {
        if (component.currentSetting == null) continue;
        final componentAdjustmentValues = component.currentSetting?.adjustmentValues;
        if (componentAdjustmentValues == null) continue;
        for (final adjustmentValue in componentAdjustmentValues.entries) {
          adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
        }
      }
    }

  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    // Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    // Pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _saveSetting() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    Navigator.pop(
      context,
      Setting(
        id: widget.setting.id,
        name: name,
        datetime: _selectedDateTime,
        notes: notes,
        bike: bike,
        adjustmentValues: adjustmentValues,
        position: widget.setting.position,
        place: widget.setting.place,
        temperature: widget.setting.temperature,
      ),
    );
  }

  void _onAdjustmentValueChanged(Adjustment adjustment, dynamic newValue) {
    adjustmentValues[adjustment] = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Setting'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSetting),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Setting Name',
              border: OutlineInputBorder(),
              hintText: 'Enter setting name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Add notes (optional)',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today),
                label: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                ),
                onPressed: _pickDateTime,
              ),
              Chip(
                avatar: Icon(Icons.my_location),
                label: Text("${_currentPlace?.thoroughfare} ${_currentPlace?.subThoroughfare}, ${_currentPlace?.locality}, ${_currentPlace?.country}"),
              ),
              Chip(
                avatar: Icon(Icons.arrow_upward),
                label: Text("Altitude: ${_currentLocation?.altitude?.round()} m"),
              ),
              Chip(
                avatar: Icon(Icons.thermostat), 
                label: Text("${temperature?.toStringAsFixed(1)} °C")
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Bike>(
            initialValue: bike,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Bike',
              border: OutlineInputBorder(),
              hintText: "Choose a bike for this component",
            ),
            items: widget.bikes.map((b) {
              return DropdownMenuItem<Bike>(
                value: b,
                child: Text(b.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (Bike? newBike) {
              if (newBike == null) return;
              setState(() {
                bike = newBike;
                onBikeChange();
              });
            },
          ),
          const SizedBox(height: 24),
          if (bikeComponents.isEmpty)
            const Center(
              child: Text(
                'No components available.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...bikeComponents.map((bikeComponent) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(bikeComponent.name),
                      subtitle: Text('${bikeComponent.adjustments.length} adjustments'),
                      leading: const Icon(Icons.casino),
                    ),
                    AdjustmentSetList(
                      key: ValueKey(bikeComponent.id),
                      adjustments: bikeComponent.adjustments,
                      initialAdjustmentValues: bikeComponent.currentSetting?.adjustmentValues ?? <Adjustment, dynamic>{},
                      onAdjustmentValueChanged: _onAdjustmentValueChanged,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
