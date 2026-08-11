import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_categorical_adjustment.dart';
import 'adjustment_page.dart';

class CategoricalAdjustmentPage extends StatefulWidget {
  final CategoricalAdjustment? adjustment;
  final AdjustmentPageMode mode;

  const CategoricalAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
  });

  factory CategoricalAdjustmentPage.add({Key? key}) =>
      CategoricalAdjustmentPage._(key: key, mode: AdjustmentPageMode.add);

  factory CategoricalAdjustmentPage.edit({Key? key, required CategoricalAdjustment adjustment}) =>
      CategoricalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit);

  factory CategoricalAdjustmentPage.duplicate({Key? key, required CategoricalAdjustment adjustment}) =>
      CategoricalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate);

  factory CategoricalAdjustmentPage.template({Key? key, required CategoricalAdjustment adjustment}) =>
      CategoricalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template);

  @override
  State<CategoricalAdjustmentPage> createState() => _CategoricalAdjustmentPageState();
}

class _CategoricalAdjustmentPageState extends State<CategoricalAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late List<TextEditingController> _optionControllers;
  late List<FocusNode> _optionFocusNodes;
  late Set<String> _initialOptions;

  bool _multiSelect = false;
  bool _counted = false;
  List<String>? _previewValues;
  late CategoricalAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _multiSelect = widget.adjustment?.multiSelect ?? false;
    _counted = widget.adjustment?.counted ?? false;
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    if (widget.adjustment == null) {
      _optionControllers = [TextEditingController()];
    } else {
      _optionControllers = widget.adjustment!.options.map((option) => TextEditingController(text: option)).toList();
    }
    for (final optionController in _optionControllers) {
      optionController.addListener(_changeListener);
    }
    _optionFocusNodes = List.generate(_optionControllers.length, (_) => FocusNode());
    _initialOptions = widget.adjustment?.options.toSet() ?? {};

    _previewAdjustment = widget.adjustment ?? _composePreview();
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  /// Builds the live preview adjustment from the current form state.
  CategoricalAdjustment _composePreview() {
    final notes = _notesController.text.trim();
    return CategoricalAdjustment(
      name: _nameController.text.trim(),
      notes: notes.isEmpty ? null : notes,
      unit: widget.adjustment?.unit,
      options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
      multiSelect: _multiSelect,
      counted: _counted,
    );
  }

  void _changeListener() {
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet();

    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') ||
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        _multiSelect != (widget.adjustment?.multiSelect ?? false) ||
        _counted != (widget.adjustment?.counted ?? false) ||
        !setEquals(_initialOptions, options);
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
    for (final c in _optionControllers) {
      c.removeListener(_changeListener);
      c.dispose();
    }
    for (final focusNode in _optionFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addOptionField() {
    final newFocusNode = FocusNode();
    setState(() {
      final newController = TextEditingController();
      newController.addListener(_changeListener);
      _optionControllers.add(newController);
      _optionFocusNodes.add(newFocusNode);
      _previewValues = null;
      _previewAdjustment = _composePreview();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) newFocusNode.requestFocus();
    });
  }

  void _removeOptionField(int index) {
    if (_optionControllers.length == 1) return; // keep at least one field
    setState(() {
      _optionControllers[index].removeListener(_changeListener);
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _optionFocusNodes[index].dispose();
      _optionFocusNodes.removeAt(index);
      _previewValues = null;
      _previewAdjustment = _composePreview();
    });
  }

  bool _hasDuplicateOptions(List<String> options) {
    final seen = <String>{};
    for (final option in options) {
      if (seen.contains(option)) return true;
      seen.add(option);
    }
    return false;
  }

  String? _validateOptions() {
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (options.isEmpty) return 'At least one option is required.';
    if (_hasDuplicateOptions(options)) return 'Options must be unique.';
    return null;
  }

  String? _validateOption(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Option is required';
    }
    if (_hasDuplicateOptions(_optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList())) {
      return 'Options must be unique';
    }
    return null;
  }

  void _saveCategoricalAdjustment() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, CategoricalAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name,
      notes: notes.isEmpty ? null : notes,
      unit: widget.adjustment?.unit,
      options: options,
      multiSelect: _multiSelect,
      counted: _counted,
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
    final appSettings = context.watch<AppSettings>();
    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            AdjustmentPageMode.add ||
            AdjustmentPageMode.duplicate ||
            AdjustmentPageMode.template => const Text('Add Categorical Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Categorical Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveCategoricalAdjustment),
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
                            onChanged: (String newValue) {
                              setState(() {
                                _previewAdjustment = _composePreview();
                              });
                            },
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
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Options',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: _addOptionField,
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          if (widget.mode == AdjustmentPageMode.edit && !_initialOptions.every((option) => _optionControllers.map((c) => c.text.trim()).contains(option))) ...[
                            ListTile(
                              leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                              title: Text(
                                'WARNING: Renaming an option will not update existing setup values!',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 8),
                          Column(
                            children: List.generate(_optionControllers.length, (index) {
                              final controller = _optionControllers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        focusNode: _optionFocusNodes[index],
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        decoration: InputDecoration(
                                          labelText: 'Option ${index + 1}',
                                          hintText: 'Enter option value',
                                          border: const OutlineInputBorder(),
                                          errorText: _validateOptions(),
                                          fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                          filled: widget.mode == AdjustmentPageMode.edit && !widget.adjustment!.options.contains(controller.text.trim()),
                                        ),
                                        validator: _validateOption,
                                        onChanged: (String value) {
                                          setState(() {
                                            _previewValues = null;
                                            _previewAdjustment = _composePreview();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_optionControllers.length > 1)
                                      IconButton(
                                        icon: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.error),
                                        tooltip: 'Remove option',
                                        onPressed: () => _removeOptionField(index),
                                      ),
                                  ],
                                ),
                              );
                            }),
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
                            child: Column(
                              children: [
                                if (appSettings.enableMultiSelect || _multiSelect)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    tileColor: widget.mode == AdjustmentPageMode.edit && _multiSelect != (widget.adjustment?.multiSelect ?? false)
                                        ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                                        : null,
                                    title: const Text('Multi Select'),
                                    subtitle: const Text('Allow more than one selection'),
                                    value: _multiSelect,
                                    onChanged: (bool? newValue) {
                                      if (newValue == null) return;
                                      setState(() {
                                        _multiSelect = newValue;
                                        _previewValues = null;
                                        _previewAdjustment = _composePreview();
                                      });
                                      _changeListener();
                                    },
                                  ),
                                if (appSettings.enableCountedSelect || _counted)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    tileColor: widget.mode == AdjustmentPageMode.edit && _counted != (widget.adjustment?.counted ?? false)
                                        ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                                        : null,
                                    title: const Text('Count Occurrences'),
                                    subtitle: const Text('Allow the same option multiple times'),
                                    value: _counted,
                                    onChanged: (bool? newValue) {
                                      if (newValue == null) return;
                                      setState(() {
                                        _counted = newValue;
                                        _previewValues = null;
                                        _previewAdjustment = _composePreview();
                                      });
                                      _changeListener();
                                    },
                                  ),
                                TextFormField(
                                  controller: _notesController,
                                  minLines: 2,
                                  maxLines: null,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _previewAdjustment = _composePreview();
                                    });
                                  },
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    hintText: 'Enter measuring procedure/instrument/...',
                                    helperText: _notesController.text.trim().isEmpty ? null : "View these notes by tapping the ⓘ icon next to the name.",
                                    helperMaxLines: 2,
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
                  child: SetCategoricalAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: null,
                    value: _previewValues,
                    onChanged: (List<String>? newValue) {
                      setState(() {
                        _previewValues = newValue;
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
