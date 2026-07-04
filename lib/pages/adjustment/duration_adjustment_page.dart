import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_duration_adjustment.dart';
import '../../widgets/sheets/set_duration.dart';
import 'adjustment_page.dart';

class DurationAdjustmentPage extends StatefulWidget {
  final DurationAdjustment? adjustment;
  final AdjustmentPageMode mode;

  const DurationAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
  });

  factory DurationAdjustmentPage.add({Key? key}) =>
      DurationAdjustmentPage._(key: key, mode: AdjustmentPageMode.add);

  factory DurationAdjustmentPage.edit({Key? key, required DurationAdjustment adjustment}) =>
      DurationAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit);

  factory DurationAdjustmentPage.duplicate({Key? key, required DurationAdjustment adjustment}) =>
      DurationAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate);

  factory DurationAdjustmentPage.template({Key? key, required DurationAdjustment adjustment}) =>
      DurationAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template);

  @override
  State<DurationAdjustmentPage> createState() => _DurationAdjustmentPageState();
}

class _DurationAdjustmentPageState extends State<DurationAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  final FocusNode _minFocusNode = FocusNode(canRequestFocus: false);
  final FocusNode _maxFocusNode = FocusNode(canRequestFocus: false);

  Duration _previewValue = Duration.zero;
  late DurationAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min == null ? null : Adjustment.formatValue(widget.adjustment?.min));
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max == null ? null : Adjustment.formatValue(widget.adjustment?.max));
    _maxController.addListener(_changeListener);

    _previewAdjustment = widget.adjustment ?? DurationAdjustment(
      name: '',
      notes: null,
      unit: null,
    );
    _previewValue = _previewAdjustment.min ?? Duration.zero;
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') ||
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        _previewAdjustment.min != widget.adjustment?.min ||
        _previewAdjustment.max != widget.adjustment?.max;
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
    _minController.removeListener(_changeListener);
    _minController.dispose();
    _maxController.removeListener(_changeListener);
    _maxController.dispose();
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  void _saveDurationAdjustment() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, DurationAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name,
      notes: notes.isEmpty ? null : notes,
      min: _previewAdjustment.min,
      max: _previewAdjustment.max,
      unit: widget.adjustment?.unit,
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

  void _updatePreview({required Duration? min, required Duration? max}) {
    final notes = _notesController.text.trim();
    setState(() {
      _previewAdjustment = DurationAdjustment(
        id: _previewAdjustment.id,
        name: _nameController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        unit: _previewAdjustment.unit,
        min: min,
        max: max,
      );
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
            AdjustmentPageMode.template => const Text('Add Duration Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Duration Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveDurationAdjustment),
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
                            onChanged: (_) => _updatePreview(
                              min: _previewAdjustment.min,
                              max: _previewAdjustment.max,
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _saveDurationAdjustment(),
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
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _minController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  focusNode: _minFocusNode,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    showSetDurationSheet(
                                      context: context,
                                      adjustment: DurationAdjustment(name: 'Min', notes: null, unit: null, max: _previewAdjustment.max),
                                      value: _previewAdjustment.min,
                                      onChanged: (Duration newValue) {
                                        _minController.text = Adjustment.formatValue(newValue);
                                        _updatePreview(min: newValue, max: _previewAdjustment.max);
                                      }
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Min Duration (optional)',
                                    hintText: 'Select minimum duration',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.vertical_align_bottom),
                                    suffixIcon: _minController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _minController.clear();
                                              _updatePreview(min: null, max: _previewAdjustment.max);
                                            },
                                          )
                                        : null,
                                    fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    filled: widget.mode == AdjustmentPageMode.edit && _previewAdjustment.min != widget.adjustment?.min,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _maxController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  focusNode: _maxFocusNode,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    showSetDurationSheet(
                                      context: context,
                                      adjustment: DurationAdjustment(name: 'Max', notes: null, unit: null, min: _previewAdjustment.min),
                                      value: _previewAdjustment.max,
                                      onChanged: (Duration newValue) {
                                        _maxController.text = Adjustment.formatValue(newValue);
                                        _updatePreview(min: _previewAdjustment.min, max: newValue);
                                      }
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Max Duration (optional)',
                                    hintText: 'Select maximum duration',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.vertical_align_top),
                                    suffixIcon: _maxController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _maxController.clear();
                                              _updatePreview(min: _previewAdjustment.min, max: null);
                                            },
                                          )
                                        : null,
                                    fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    filled: widget.mode == AdjustmentPageMode.edit && _previewAdjustment.max != widget.adjustment?.max,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _notesController,
                                  minLines: 2,
                                  maxLines: null,
                                  onChanged: (_) => _updatePreview(
                                    min: _previewAdjustment.min,
                                    max: _previewAdjustment.max,
                                  ),
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
                              ],
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
            ],
          ),
        ),
      ),
    );
  }
}
