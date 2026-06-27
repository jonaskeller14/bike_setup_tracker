import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../icons/simple_icons.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/person.dart';
import '../models/strava/strava_athlete.dart';
import '../repositories/app_repository.dart';
import '../services/subscription_service.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/lists/adjustment_edit_list.dart';
import '../widgets/sheets/person_add_adjustment.dart';
import '../widgets/text/section_title.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import 'adjustment/duration_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/text_adjustment_page.dart';

enum PersonPageMode {
  add,
  edit,
  duplicate,
}

class PersonPage extends StatefulWidget {
  final Person? person;
  final PersonPageMode mode;

  const PersonPage._({super.key, this.person, required this.mode});

  factory PersonPage.add({Key? key}) => 
    PersonPage._(key: key, mode: PersonPageMode.add);

  factory PersonPage.edit({Key? key, required Person person}) => 
    PersonPage._(key: key, person: person, mode: PersonPageMode.edit);

  factory PersonPage.duplicate({Key? key, required Person person}) => 
    PersonPage._(key: key, person: person, mode: PersonPageMode.duplicate);

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;

  int? _initialStravaAthlete;
  int? _stravaAthlete;

  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.person?.notes);
    _notesController.addListener(_changeListener);

    _initialStravaAthlete = widget.person?.stravaAthlete;
    _stravaAthlete = _initialStravaAthlete;

    if (widget.mode != PersonPageMode.add) _expanded = true;

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
        _notesController.text.trim() != (widget.person?.notes ?? '') ||
        _stravaAthlete != _initialStravaAthlete ||
        !listEquals(_adjustments, _initialAdjustments);
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

  Future<void> _addAdjustment<T extends Adjustment>({VoidCallback? onChanged}) async {
    final adjustment = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => switch(T) {
        const (BooleanAdjustment)       => BooleanAdjustmentPage.add(),
        const (CategoricalAdjustment)   => CategoricalAdjustmentPage.add(),
        const (StepAdjustment)          => StepAdjustmentPage.add(),
        const (NumericalAdjustment)     => NumericalAdjustmentPage.add(),
        const (TextAdjustment)          => TextAdjustmentPage.add(),
        const (DurationAdjustment)      => DurationAdjustmentPage.add(),
        Type() => throw UnimplementedError(),
      }),
    );
    if (adjustment == null) return;
    setState(() => _adjustments.add(adjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _addAdjustmentFromPreset(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final newAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment.deepCopy()) {
        final BooleanAdjustment a     => BooleanAdjustmentPage.template(adjustment: a),
        final CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a),
        final StepAdjustment a        => StepAdjustmentPage.template(adjustment: a),
        final NumericalAdjustment a   => NumericalAdjustmentPage.template(adjustment: a),
        final TextAdjustment a        => TextAdjustmentPage.template(adjustment: a),
        final DurationAdjustment a    => DurationAdjustmentPage.template(adjustment: a),
      }),
    );
    if (newAdjustment == null) return;
    setState(() => _adjustments.add(newAdjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _editAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final editedAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment) {
        final BooleanAdjustment a     => BooleanAdjustmentPage.edit(adjustment: a),
        final CategoricalAdjustment a => CategoricalAdjustmentPage.edit(adjustment: a),
        final StepAdjustment a        => StepAdjustmentPage.edit(adjustment: a),
        final NumericalAdjustment a   => NumericalAdjustmentPage.edit(adjustment: a),
        final TextAdjustment a        => TextAdjustmentPage.edit(adjustment: a),
        final DurationAdjustment a    => DurationAdjustmentPage.edit(adjustment: a),
      }),
    );
    if (editedAdjustment == null) return;
    setState(() {
      final index = _adjustments.indexOf(adjustment);
      if (index != -1) {
        _adjustments[index] = editedAdjustment;
      }
    });
    _changeListener();
    onChanged?.call();
  }

  Future<void> _duplicateAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final newAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment.deepCopy()) {
        final BooleanAdjustment a     => BooleanAdjustmentPage.duplicate(adjustment: a),
        final CategoricalAdjustment a => CategoricalAdjustmentPage.duplicate(adjustment: a),
        final StepAdjustment a        => StepAdjustmentPage.duplicate(adjustment: a),
        final NumericalAdjustment a   => NumericalAdjustmentPage.duplicate(adjustment: a),
        final TextAdjustment a        => TextAdjustmentPage.duplicate(adjustment: a),
        final DurationAdjustment a    => DurationAdjustmentPage.duplicate(adjustment: a),
      }),
    );
    if (newAdjustment == null) return;
    setState(() => _adjustments.add(newAdjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> removeAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    setState(() => _adjustments.remove(adjustment));
    _changeListener();
    onChanged?.call();
  }

  void _savePerson() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }
    
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    Navigator.pop(context, Person(
      id: widget.mode == PersonPageMode.edit ? widget.person?.id : null, 
      name: name, 
      notes: notes.isEmpty ? null : notes,
      stravaAthlete: _stravaAthlete,
      adjustments: _adjustments,
      orderIndex: widget.person?.orderIndex ?? 0,
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

  void _onReorderAdjustments(int oldIndex, int newIndex, {VoidCallback? onChanged}) {
    setState(() {
      final adjustment = _adjustments.removeAt(oldIndex);
      _adjustments.insert(newIndex, adjustment);
    });
    _changeListener();
    onChanged?.call();
  }

  Widget _emptyAdjustmentsInfo({String? errorText, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: errorText != null 
              ? Theme.of(context).colorScheme.error 
              : Theme.of(context).colorScheme.outlineVariant,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: 12,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                errorText != null ? Icons.warning_amber_rounded : Icons.add_circle_outline, 
                size: 32, 
                color: errorText != null 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
              ),
              const SizedBox(height: 12),
              Text(
                errorText ?? "No attributes yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: errorText != null 
                      ? Theme.of(context).colorScheme.error 
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                errorText != null 
                    ? "Tap here to add the first attribute" 
                    : "Tap 'Add Attribute' to define parameters for this person",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: errorText != null 
                      ? Theme.of(context).colorScheme.error.withValues(alpha: 0.7) 
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameField() {
    return TextFormField(
      controller: _nameController,
      onFieldSubmitted: (_) => _savePerson(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: widget.mode == PersonPageMode.add,
      onChanged: (value) => setState(() {}), // see filled/fillColor
      decoration: InputDecoration(
        labelText: 'Person Name',
        border: const OutlineInputBorder(),
        hintText: 'Enter Person name',
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == PersonPageMode.edit && _nameController.text.trim() != widget.person?.name,
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return 'Name is required';
        return null;
      },
    );
  }

  Widget _notesField() {
    return TextFormField(
      controller: _notesController,
      minLines: 2,
      maxLines: null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) => setState(() {}), // see filled/fillColor
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Enter notes about the person...',
        border: const OutlineInputBorder(),
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == PersonPageMode.edit && _notesController.text.trim() != (widget.person?.notes ?? ""),
      ),
    );
  }

  Widget _stravaAthleteDropdown({required Map<String, Person> existingPersons, required Map<int, StravaAthlete> stravaAthletes}) {
    return DropdownButtonFormField<int?>(
      initialValue: _stravaAthlete,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Strava Athlete',
        border: const OutlineInputBorder(),
        hintText: "Link Strava Athlete",
        helperText: existingPersons.values.any((p) => p.id != widget.person?.id && p.stravaAthlete != null && p.stravaAthlete == _stravaAthlete)
          ? "WARNING: Strava Athlete already assigned to another Person"
          : null,
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == PersonPageMode.edit && _stravaAthlete != _initialStravaAthlete,
      ),
      validator: (int? newStravaAthlete) {
        if (newStravaAthlete == null) return null;
        if (!stravaAthletes.containsKey(newStravaAthlete)) return "Please select valid Athlete";
        return null;
      },
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Row(
            spacing: 8,
            children: [
              Icon(Icons.link_off),
              Expanded(child: Text("NOT LINKED", overflow: TextOverflow.ellipsis))
            ],
          ),
        ),
        ...stravaAthletes.values.map((a) {
          return DropdownMenuItem<int>(
            value: a.id,
            child: Row(
              spacing: 8,
              children: [
                const Icon(SimpleIcons.strava),
                Expanded(child: Text("${a.firstname} ${a.lastname}", overflow: TextOverflow.ellipsis))
              ],
            ),
          );
        }),
        if (_stravaAthlete != null && !stravaAthletes.containsKey(_stravaAthlete))
          DropdownMenuItem<int>(
          value: _stravaAthlete,
          child: Row(
            spacing: 8,
            children: [
              Icon(SimpleIcons.strava, color: Theme.of(context).colorScheme.error),
              Expanded(child: Text("ATHLETE NOT FOUND", overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.error)))
            ],
          ),
        ),
      ],
      onChanged: (int? newStravaAthlete) {
        setState(() => _stravaAthlete = newStravaAthlete);
        _changeListener();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final existingPersons = appRepository.persons;
    final stravaAthletes = appRepository.stravaAthletes;

    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            PersonPageMode.add || PersonPageMode.duplicate => const Text('Add Person'),
            PersonPageMode.edit => const Text('Edit Person'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _savePerson),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _nameField(),
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
                              _notesField(),
                              if (context.read<AppSettings>().enableStrava && subscriptionService.hasStravaEntitlement) ...[
                                const SizedBox(height: 12),
                                _stravaAthleteDropdown(existingPersons: existingPersons, stravaAthletes: stravaAthletes),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle(title: "Attributes"),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FormField<List<Adjustment>>(
                      initialValue: _adjustments,
                      builder: (FormFieldState<List<Adjustment>> field) {
                        void notify() => field.didChange(List.from(_adjustments));

                        void showAddBottomSheet() => showPersonAddAdjustmentBottomSheet(
                          context: context,
                          addAdjustmentFromPreset: (a) => _addAdjustmentFromPreset(a, onChanged: notify),
                          addAdjustment: <T extends Adjustment>() => _addAdjustment<T>(onChanged: notify),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _adjustments.isNotEmpty
                                ? AdjustmentEditList(
                                    adjustments: _adjustments,
                                    initialAdjustments: widget.mode == PersonPageMode.edit
                                        ? Map.fromEntries(widget.person!.adjustments.map((a) => MapEntry(a.id, a)))
                                        : null,
                                    editAdjustment: (a) => _editAdjustment(a, onChanged: notify),
                                    duplicateAdjustment: (a) => _duplicateAdjustment(a, onChanged: notify),
                                    removeAdjustment: (a) => removeAdjustment(a, onChanged: notify),
                                    onReorderAdjustments: (int oldIndex, int newIndex) => _onReorderAdjustments(oldIndex, newIndex, onChanged: notify),
                                  )
                                : _emptyAdjustmentsInfo(
                                    errorText: field.errorText,
                                    onTap: showAddBottomSheet,
                                  ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: showAddBottomSheet,
                                icon: const Icon(Icons.add),
                                label: const Text("Add Attribute"),
                              ),
                            ),
                            if (field.hasError && _adjustments.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                                child: Text(
                                  field.errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
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
