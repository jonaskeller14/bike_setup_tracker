import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_duration_adjustment.dart';

class DurationAdjustmentPage extends StatefulWidget {
  final DurationAdjustment? adjustment;
  const DurationAdjustmentPage({super.key, this.adjustment});

  @override
  State<DurationAdjustmentPage> createState() => _DurationAdjustmentPageState();
}

class _DurationAdjustmentPageState extends State<DurationAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  Duration _previewValue = Duration();
  DurationAdjustment _previewAdjustment = DurationAdjustment(
    name: '', 
    notes: null,
    unit: null,
  );
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);

    if (widget.adjustment != null) {
      _previewAdjustment = widget.adjustment!;
    }
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') || 
        _notesController.text.trim() != (widget.adjustment?.notes ?? '');
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

  void _saveDurationAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();

    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, DurationAdjustment(
        name: name, 
        notes: notes.isEmpty ? null : notes, 
        min: null, 
        max: null, 
        unit: null,
      ));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.notes = notes.isEmpty ? null : notes;
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
          title: widget.adjustment == null ? const Text('Add Duration Adjustment') : const Text('Edit Duration Adjustment'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveDurationAdjustment),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          autofocus: widget.adjustment == null,
                          decoration: InputDecoration(
                            labelText: 'Adjustment Name',
                            hintText: 'Enter Adjustment Name',
                            border: OutlineInputBorder(),
                            fillColor: Colors.orange.withValues(alpha: 0.08),
                            filled: widget.adjustment != null && _nameController.text.trim() != widget.adjustment?.name,
                          ),
                          validator: _validateName,
                          onChanged: (String value) {
                            setState(() {
                              _previewAdjustment = DurationAdjustment(
                                name: _nameController.text.trim(),
                                notes: _previewAdjustment.notes,
                                unit: _previewAdjustment.unit,
                                min: _previewAdjustment.min,
                                max: _previewAdjustment.max,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          minLines: 2,
                          maxLines: null,
                          onChanged: (String? value) {
                            setState(() {
                              _previewAdjustment = DurationAdjustment(
                                name: _nameController.text.trim(),
                                notes: (value == null || value.isEmpty) ? null : value,
                                unit: _previewAdjustment.unit, 
                                min: _previewAdjustment.min,
                                max: _previewAdjustment.max,
                              );
                            });
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Enter measuring procedure/instrument/...',
                            border: OutlineInputBorder(),
                            fillColor: Colors.orange.withValues(alpha: 0.08),
                            filled: widget.adjustment != null && _notesController.text.trim() != (widget.adjustment?.notes ?? ""),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                Container(
                  padding: EdgeInsetsGeometry.fromLTRB(16, 32, 16, 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor)), color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                  child: Card(
                    child: SetDurationAdjustmentWidget(
                      key: ValueKey(_previewAdjustment),
                      adjustment: _previewAdjustment,
                      initialValue: Duration.zero,
                      value: _previewValue,
                      onChanged: (Duration? newValue) {
                        setState(() {
                          _previewValue = newValue ?? Duration.zero;
                        });
                      },
                      highlighting: false,
                    ),
                  ),
                ),
                Positioned(
                  top: -1, 
                  left: -1, 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        bottomRight: const Radius.circular(6),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: Text(
                      'Preview only — changes won’t be saved',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
