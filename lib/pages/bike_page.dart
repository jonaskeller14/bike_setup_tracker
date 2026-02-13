import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/app_data.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/filtered_data.dart';
import '../widgets/dialogs/discard_changes.dart';

enum BikePageMode {
  add,
  edit,
  duplicate,
}

class BikePage extends StatefulWidget {
  final Bike? bike;
  final BikePageMode mode;

  const BikePage._({super.key, this.bike, required this.mode});

  factory BikePage.add({Key? key}) => 
    BikePage._(key: key, mode: BikePageMode.add);

  factory BikePage.edit({Key? key, required Bike bike}) => 
    BikePage._(key: key, bike: bike, mode: BikePageMode.edit);

  factory BikePage.duplicate({Key? key, required Bike bike}) => 
    BikePage._(key: key, bike: bike, mode: BikePageMode.duplicate);

  @override
  State<BikePage> createState() => _BikePageState();
}

class _BikePageState extends State<BikePage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;

  String? _initialPerson;
  String? _person;

  String? _initialStravaGear;
  String? _stravaGear;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bike?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.bike?.notes);
    _notesController.addListener(_changeListener);
    
    _initialPerson = widget.bike?.person;
    _person = _initialPerson;

    _initialStravaGear = widget.bike?.stravaGear;
    _stravaGear = _initialStravaGear;

    if (widget.mode != BikePageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.bike?.name ?? '') || 
        _notesController.text.trim() != (widget.bike?.notes ?? '') ||
        _person != _initialPerson || 
        _stravaGear != _initialStravaGear;
    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    super.dispose();
  }

  void _saveBike() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;

    Navigator.pop(context, Bike(
      id: widget.mode == BikePageMode.edit ? widget.bike!.id : null, 
      name: name, 
      notes: notes.isEmpty ? null : notes,
      person: _person,
      stravaGear: _stravaGear,
    ));
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final filteredData = context.read<FilteredData>();
    final persons = filteredData.persons;
    final appData = context.read<AppData>();
    final stravaGears = appData.stravaGears;

    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            BikePageMode.add || BikePageMode.duplicate => const Text('Add Bike'),
            BikePageMode.edit => const Text('Edit Bike'),
          },
          actions: [
            IconButton(
              icon: const Icon(Icons.check), 
              onPressed: _saveBike
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  onFieldSubmitted: (_) => _saveBike(),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  autofocus: widget.mode == BikePageMode.add,
                  decoration: InputDecoration(
                    labelText: 'Bike Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter bike name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == BikePageMode.edit && _nameController.text.trim() != widget.bike?.name,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a bike name';
                    }
                    return null;
                  },
                ),
                if (appSettings.enablePerson) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _person,
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Bike Owner',
                      border: OutlineInputBorder(),
                      hintText: "Choose an owner for this bike",
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == BikePageMode.edit && _person != _initialPerson,
                    ),
                    validator: (String? newPerson) {
                      if (newPerson == null) return null;
                      if (!persons.containsKey(newPerson)) return "Please select valid person";
                      return null;
                    },
                    items: persons.values.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Row(
                          spacing: 8,
                          children: [
                            const Icon(Icons.person),
                            Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis))
                          ],
                        ),
                      );
                    }).toList() + [
                      if (_person != null && !persons.containsKey(_person))
                       DropdownMenuItem<String>(
                        value: _person,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(Icons.person, color: Theme.of(context).colorScheme.error),
                            Expanded(child: Text("PERSON NOT FOUND", overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                          ],
                        ),
                      ), 
                    ],
                    onChanged: (String? newPerson) {
                      setState(() => _person = newPerson);
                      _changeListener();
                    },
                  ),
                ],
                if (!_expanded)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (!_expanded) _expanded = !_expanded;
                        });
                      },
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(_expanded ? "Hide Additional Fields" : "Show Additional Fields"),
                    ),
                  ),
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Enter Bike brand, model, size, year, costs, ...',
                      border: OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == BikePageMode.edit && _notesController.text.trim() != (widget.bike?.notes ?? ""),
                    ),
                  ),
                  if (appSettings.enableStrava) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                    initialValue: _stravaGear,
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Strava Gear',
                      border: OutlineInputBorder(),
                      hintText: "Link Strava Gear",
                      prefixIcon: const Icon(Icons.link),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == BikePageMode.edit && _stravaGear != _initialStravaGear,
                    ),
                    validator: (String? newStravaGear) {
                      if (newStravaGear == null) return null;
                      if (!stravaGears.containsKey(newStravaGear)) return "Please select valid Gear";
                      return null;
                    },
                    items: stravaGears.values.map((g) {
                      return DropdownMenuItem<String>(
                        value: g.id,
                        child: Row(
                          spacing: 8,
                          children: [
                            const Icon(SimpleIcons.strava),
                            Expanded(child: Text(g.name, overflow: TextOverflow.ellipsis))
                          ],
                        ),
                      );
                    }).toList() + [
                      if (_stravaGear != null && !stravaGears.containsKey(_stravaGear))
                       DropdownMenuItem<String>(
                        value: _stravaGear,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(SimpleIcons.strava, color: Theme.of(context).colorScheme.error),
                            Expanded(child: Text("GEAR NOT FOUND", overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                          ],
                        ),
                      ), 
                    ],
                    onChanged: (String? newStravaGear) {
                      setState(() => _stravaGear = newStravaGear);
                      _changeListener();
                    },
                  ),
                  ]
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
