import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/component.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_sag_adjustment.dart';
import 'adjustment_page.dart';

/// Sag is a numerical fixed to 0..100 %, so this page drops the unit picker and
/// the min/max fields and asks for the reference travel instead.
class SagAdjustmentPage extends StatefulWidget {
  final SagAdjustment? adjustment;
  final AdjustmentPageMode mode;
  final ComponentType? componentType;

  const SagAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
    this.componentType,
  });

  factory SagAdjustmentPage.add({Key? key, ComponentType? componentType}) =>
      SagAdjustmentPage._(key: key, mode: AdjustmentPageMode.add, componentType: componentType);

  factory SagAdjustmentPage.edit({Key? key, required SagAdjustment adjustment, ComponentType? componentType}) =>
      SagAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit, componentType: componentType);

  factory SagAdjustmentPage.duplicate({Key? key, required SagAdjustment adjustment, ComponentType? componentType}) =>
      SagAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate, componentType: componentType);

  factory SagAdjustmentPage.template({Key? key, required SagAdjustment adjustment, ComponentType? componentType}) =>
      SagAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template, componentType: componentType);

  @override
  State<SagAdjustmentPage> createState() => _SagAdjustmentPageState();
}

class _SagAdjustmentPageState extends State<SagAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _travelController;

  String? _previewValue;
  late SagAdjustment _previewAdjustment;

  String get _travelLabel => switch (widget.componentType) {
        ComponentType.fork => 'Travel',
        ComponentType.shock => 'Stroke',
        _ => 'Travel / Stroke',
      };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    _travelController = TextEditingController(
      text: widget.adjustment?.referenceTravelMm == null
          ? null
          : Adjustment.formatValue(widget.adjustment!.referenceTravelMm),
    );
    _travelController.addListener(_changeListener);

    _previewAdjustment = widget.adjustment ?? SagAdjustment(name: '', notes: null);
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') ||
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        _travel() != widget.adjustment?.referenceTravelMm;
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
    _travelController.removeListener(_changeListener);
    _travelController.dispose();
    super.dispose();
  }

  double? _travel() => double.tryParse(_travelController.text.trim());

  String? _validateTravel(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final v = double.tryParse(value);
    if (v == null) return 'Valid number required';
    if (v <= 0) return 'Must be greater than 0';
    return null;
  }

  Future<void> _saveSagAdjustment() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();

    _formHasChanges = false;
    final adjustment = SagAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name,
      notes: notes.isEmpty ? null : notes,
      referenceTravelMm: _travel(),
    );
    Navigator.pop(context, adjustment);
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  SagAdjustment _composePreview() {
    final notes = _notesController.text.trim();
    return SagAdjustment(
      id: _previewAdjustment.id,
      name: _nameController.text.trim(),
      notes: notes.isEmpty ? null : notes,
      referenceTravelMm: _validateTravel(_travelController.text) == null ? _travel() : null,
    );
  }

  void _updatePreview({bool resetValue = false}) {
    setState(() {
      _previewAdjustment = _composePreview();
      if (resetValue) _previewValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            AdjustmentPageMode.add ||
            AdjustmentPageMode.duplicate ||
            AdjustmentPageMode.template => const Text('Add SAG Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit SAG Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveSagAdjustment),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
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
                            onChanged: (_) => _updatePreview(),
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofocus: widget.mode == AdjustmentPageMode.add,
                            decoration: InputDecoration(
                              labelText: 'Adjustment Name',
                              hintText: 'Enter Adjustment Name',
                              border: const OutlineInputBorder(),
                              fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                              filled: widget.mode == AdjustmentPageMode.edit && _nameController.text.trim() != widget.adjustment?.name,
                            ),
                            validator: validateAdjustmentName,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _travelController,
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                            ],
                            decoration: InputDecoration(
                              labelText: '$_travelLabel (optional)',
                              hintText: 'e.g. 160',
                              helperText: _travel() == null
                                  ? 'Add it to enter and read sag in mm as well as %.'
                                  : null,
                              suffixText: 'mm',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.straighten),
                              fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                              filled: widget.mode == AdjustmentPageMode.edit && _travel() != widget.adjustment?.referenceTravelMm,
                            ),
                            validator: _validateTravel,
                            onChanged: (_) => _updatePreview(),
                          ),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _expanded = !_expanded),
                              icon: Icon(_expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              ),
                              label: Text(_expanded
                                  ? "Hide Additional Fields"
                                  : "Show Additional Fields"
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _expanded,
                            maintainState: true,
                            child: TextFormField(
                              controller: _notesController,
                              minLines: 2,
                              maxLines: null,
                              onChanged: (_) => _updatePreview(),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                hintText: 'Enter measuring procedure/instrument/...',
                                helperText: _notesController.text.trim().isEmpty ? null : "View these notes by tapping the ⓘ icon next to the name.",
                                border: const OutlineInputBorder(),
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: widget.mode == AdjustmentPageMode.edit && _notesController.text.trim() != (widget.adjustment?.notes ?? ""),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CollapsibleAdjustmentPreview(
                child: Card(
                  child: SetSagAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: null,
                    value: _previewValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        _previewValue = newValue;
                      });
                    },
                    highlighting: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
