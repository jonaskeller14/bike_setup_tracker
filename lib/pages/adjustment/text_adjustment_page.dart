import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_text_adjustment.dart';

class TextAdjustmentPage extends StatefulWidget {
  final TextAdjustment? adjustment;
  const TextAdjustmentPage({super.key, this.adjustment});

  @override
  State<TextAdjustmentPage> createState() => _TextAdjustmentPageState();
}

class _TextAdjustmentPageState extends State<TextAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late bool _prefill;

  String _previewValue = '';
  TextAdjustment _previewAdjustment = TextAdjustment(
    name: '', 
    notes: null,
    unit: null,
    prefill: true,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    _prefill = widget.adjustment?.prefill ?? true;

    if (widget.adjustment != null) {
      _previewAdjustment = widget.adjustment!;
      _expanded = true;
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

  void _saveTextAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, TextAdjustment(
        name: name, 
        notes: notes.isEmpty ? null : notes, 
        unit: null,
        prefill: _prefill,
      ));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.notes = notes.isEmpty ? null : notes;
      widget.adjustment!.unit = null;
      widget.adjustment!.prefill = _prefill;
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
            IconButton(icon: const Icon(Icons.check), onPressed: _saveTextAdjustment),
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
                          onChanged: (String? value) {
                            setState(() {
                              _previewAdjustment = TextAdjustment(
                                name: value ?? '',
                                notes: _previewAdjustment.notes,
                                unit: _previewAdjustment.unit,
                                prefill: _previewAdjustment.prefill,
                              );
                            });
                          },
                          onFieldSubmitted: (_) => _saveTextAdjustment(),
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
                        ),
                        if (!_expanded) ...[
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
                        ],
                        if (_expanded) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            minLines: 2,
                            maxLines: null,
                            onChanged: (String? value) {
                              setState(() {
                                _previewAdjustment = TextAdjustment(
                                  name: _previewAdjustment.name, 
                                  notes: (value == null || value.isEmpty) ? null : value,
                                  unit: _previewAdjustment.unit,
                                  prefill: _previewAdjustment.prefill,
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
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text("Prefill text with baseline setup"),
                            subtitle: const Text("When disabled, the text field will always start empty"),
                            value: _prefill,
                            onChanged: (value) {
                              setState(() {
                                _prefill = value;
                                _previewValue = _prefill ? "<Text from baseline setup>": "";
                                _previewAdjustment = TextAdjustment(
                                  name: _previewAdjustment.name,
                                  notes: _previewAdjustment.notes,
                                  unit: _previewAdjustment.unit,
                                  prefill: value,
                                );
                              });
                            },
                          ),
                        ],
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
                    child: SetTextAdjustmentWidget(
                      key: ValueKey(_previewAdjustment),
                      adjustment: _previewAdjustment,
                      initialValue: _previewAdjustment.prefill ? "<Text from baseline setup>" : null,
                      value: _previewValue, 
                      onChanged: (String newValue) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _previewValue = newValue;
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
