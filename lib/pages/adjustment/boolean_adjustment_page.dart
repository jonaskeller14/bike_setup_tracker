import 'package:flutter/material.dart';
import '../../models/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';

class BooleanAdjustmentPage extends StatefulWidget {
  final BooleanAdjustment? adjustment;
  const BooleanAdjustmentPage({super.key, this.adjustment});

  @override
  State<BooleanAdjustmentPage> createState() => _BooleanAdjustmentPageState();
}

class _BooleanAdjustmentPageState extends State<BooleanAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
  }

  void _changeListener() {
    final nameHasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '');
    if (_formHasChanges != nameHasChanges) {
      setState(() {
        _formHasChanges = nameHasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    super.dispose();
  }

  void _saveBooleanAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, BooleanAdjustment(name: name, unit: null));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.unit = null;
      Navigator.pop(context, widget.adjustment);
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.adjustment == null ? const Text('Add On/Off Adjustment') : const Text('Edit On/Off Adjustment'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveBooleanAdjustment),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    onFieldSubmitted: (_) => _saveBooleanAdjustment(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    autofocus: widget.adjustment == null,
                    decoration: const InputDecoration(
                      labelText: 'Adjustment Name',
                      hintText: 'Enter Adjustment Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
