import 'package:flutter/material.dart';
import '../models/bike.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bike?.name);
    _nameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final newHasChanges = _nameController.text.trim() != (widget.bike?.name ?? '');
    if (_formHasChanges != newHasChanges) {
      setState(() {
        _formHasChanges = newHasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _saveBike() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    _formHasChanges = false;
    if (widget.bike == null) {
      Navigator.pop(context, Bike(name: name));
    } else {
      widget.bike!.name = name;
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
        body: Padding(
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
                  decoration: const InputDecoration(
                    labelText: 'Bike Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter bike name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a bike name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
