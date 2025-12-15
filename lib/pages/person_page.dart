import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/person.dart';
import '../models/adjustment/adjustment.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import 'adjustment/text_adjustment_page.dart';
import 'adjustment/duration_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/person_add_adjustment.dart';

class PersonPage extends StatefulWidget {
  final Person? person;

  const PersonPage({super.key, this.person});

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  static const _enableDurationAdjustment = false;
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name);
    _nameController.addListener(_changeListener);
    _adjustments = widget.person == null 
        ? [
            NumericalAdjustment(name: 'Body weight', notes: null, unit: 'kg', min: 0.0), 
            NumericalAdjustment(name: 'Height', notes: null, unit: 'cm', min: 0.0),
          ] 
        : List.from(widget.person!.adjustments);
    _initialAdjustments = List.from(_adjustments);
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.person?.name ?? '') ||
        _initialAdjustments.length != _adjustments.length || 
        _adjustments.asMap().entries.any((entry) => entry.value != _initialAdjustments[entry.key]);
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

  Future<void> _addAdjustment<T extends Adjustment>(Widget page) async {
    final adjustment = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (adjustment == null) return;

    setState(() {
      _adjustments.add(adjustment);
    });
    
    _changeListener();
  }

  Future<void> _addAdjustmentFromPreset(Adjustment adjustment) async {
    final newAdjustment = await _editAdjustment(adjustment.deepCopy());
    if (newAdjustment == null) return;
    setState(() {
      _adjustments.add(newAdjustment);
    });
    _changeListener();
  }

  Future<Adjustment?> _editAdjustment(Adjustment adjustment) async {
    final Adjustment? editedAdjustment;
    if (adjustment is BooleanAdjustment) {
      editedAdjustment = await Navigator.push<BooleanAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => BooleanAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is CategoricalAdjustment) {
      editedAdjustment = await Navigator.push<CategoricalAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => CategoricalAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is StepAdjustment) {
      editedAdjustment = await Navigator.push<StepAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => StepAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is NumericalAdjustment) {
      editedAdjustment = await Navigator.push<NumericalAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => NumericalAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is TextAdjustment) {
      editedAdjustment = await Navigator.push<TextAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => TextAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is DurationAdjustment) {
      editedAdjustment = await Navigator.push<DurationAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => DurationAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else {
      throw Exception("Not implemented.");
    }
    if (editedAdjustment == null) return null;
    setState(() {
      final index = _adjustments.indexOf(adjustment);
      if (index != -1) {
        _adjustments[index] = editedAdjustment!;
      }
    });
    if (widget.person != null) widget.person!.lastModified = DateTime.now();
    return editedAdjustment;
  }

  Future<void> removeAdjustment(Adjustment adjustment) async {
    setState(() {
      _adjustments.remove(adjustment);
    });
    _changeListener();
  }

  void _savePerson() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    _formHasChanges = false;
    if (widget.person == null) {
      Navigator.pop(context, Person(name: name, adjustments: _adjustments));
    } else {
      widget.person!.name = name;
      widget.person!.adjustments = _adjustments;
      widget.person!.lastModified = DateTime.now();
      Navigator.pop(context, widget.person);
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

  Widget _buildGuideRow(IconData icon, String type, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13, height: 1.3),
                children: [
                  TextSpan(
                    text: "$type: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  TextSpan(
                    text: example,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontStyle: FontStyle.italic)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onReorderAdjustments(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    setState(() {
      final adjustment = _adjustments.removeAt(oldIndex);
      _adjustments.insert(adjustedNewIndex, adjustment);
    });
    _changeListener();
  }

  Widget _emptyAdjustmentsInfo() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              "No attributes yet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Define what personal attributes you want to track by tapping the button below.",
          style: TextStyle(height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        Text(
          "Examples:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 4),
        _buildGuideRow(Icons.speed, "Numerical", "Body Weight, Height, Age"),
        _buildGuideRow(Icons.rotate_right, "Step", "..."),
        _buildGuideRow(Icons.category, "Categorical", "Training status, Riding Gear, Riding style"),
        _buildGuideRow(Icons.toggle_on, "On/Off", "Wearing a backpack?"),
        if (context.read<AppSettings>().enableTextAdjustment)
          _buildGuideRow(Icons.text_snippet, "Text", "Flexible field for any other attribute"),
        if (_enableDurationAdjustment)
          _buildGuideRow(Icons.timer_outlined, "Duration", "Time span"),  //TODO: improve help text
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.person == null ? const Text('Add person') : const Text('Edit person'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _savePerson),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  onFieldSubmitted: (_) => _savePerson(),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  autofocus: widget.person == null,
                  decoration: InputDecoration(
                    labelText: 'Person Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter Person name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.person != null && _nameController.text.trim() != widget.person?.name,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _adjustments.isNotEmpty
                    ? AdjustmentEditList(
                        adjustments: _adjustments,
                        editAdjustment: _editAdjustment,
                        removeAdjustment: removeAdjustment,
                        onReorderAdjustments: _onReorderAdjustments,
                      ) 
                    : _emptyAdjustmentsInfo(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showPersonAddAdjustmentBottomSheet(
                      context: context,
                      addAdjustmentFromPreset: _addAdjustmentFromPreset,
                      addAdjustment: _addAdjustment,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Attribute"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
