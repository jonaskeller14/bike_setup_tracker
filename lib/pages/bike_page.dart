import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  String? _initialPerson;
  String? _person;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bike?.name);
    _nameController.addListener(_changeListener);
    
    _initialPerson = widget.bike?.person;
    _person = _initialPerson;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.bike?.name ?? '') || 
        _person != _initialPerson;
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
    super.dispose();
  }

  void _saveBike() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    _formHasChanges = false;

    Navigator.pop(context, Bike(
      id: widget.mode == BikePageMode.edit ? widget.bike!.id : null, 
      name: name, 
      person: _person
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
    final filteredData = context.read<FilteredData>();
    final persons = filteredData.persons;

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
                if (context.read<AppSettings>().enablePerson) ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
