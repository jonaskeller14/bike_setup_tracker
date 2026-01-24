import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../widgets/dialogs/discard_changes.dart';

class BikePage extends StatefulWidget {
  final Bike? bike;

  const BikePage({super.key, this.bike});

  @override
  State<BikePage> createState() => _BikePageState();
}

class _BikePageState extends State<BikePage> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  String? _person;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bike?.name);
    _nameController.addListener(_changeListener);
    
    _person = widget.bike?.person;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.bike?.name ?? '') || 
        _person != widget.bike?.person;
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
    if (widget.bike == null) {
      Navigator.pop(context, Bike(name: name, person: _person));
    } else {
      widget.bike!.name = name;
      widget.bike!.person = _person;
      widget.bike!.lastModified = DateTime.now();
      Navigator.pop(context, widget.bike);
    }
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
    final appData = context.watch<AppData>();
    final personOptions = Map.fromEntries(appData.persons.entries.where((p) => !p.value.isDeleted));

    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.bike == null ? const Text('Add Bike') : const Text('Edit Bike'),
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
                  autofocus: widget.bike == null,
                  decoration: InputDecoration(
                    labelText: 'Bike Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter bike name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.bike != null && _nameController.text.trim() != widget.bike?.name,
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
                  DropdownButtonFormField<Person>(
                    initialValue: personOptions[_person],
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Bike Owner',
                      border: OutlineInputBorder(),
                      hintText: "Choose an owner for this bike",
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.bike != null && _person != widget.bike?.person,
                    ),
                    validator: (Person? newPerson) {
                      if (newPerson == null) return null;
                      if (!personOptions.values.contains(newPerson)) return "Please select valid bike";
                      return null;
                    },
                    items: personOptions.values.map((p) {
                      return DropdownMenuItem<Person>(
                        value: p,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          spacing: 8,
                          children: [
                            const Icon(Icons.person),
                            Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis))
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Person? newPerson) {
                      if (newPerson == null) return;
                      setState(() {
                        _person = newPerson.id;
                      });
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
