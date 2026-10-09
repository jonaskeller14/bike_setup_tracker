import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/person.dart';
import '../utils/person_actions.dart';
import 'app_snackbar.dart';

/// The underlined, headline-sized name field of the onboarding rider slide,
/// shared so every place that creates a rider by name looks the same.
///
/// It is a bare field: the caller wraps it in a [Form] and owns the
/// controller, the focus node and the submit logic.
class RiderNameField extends StatelessWidget {
  const RiderNameField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
    this.scrollPadding = const EdgeInsets.all(20),
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmitted;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A single line to write on rather than a boxed form field: this is the one
    // thing being asked for, so it gets the weight of a headline.
    final style = Theme.of(context).textTheme.headlineSmall;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textAlign: TextAlign.center,
      style: style,
      cursorHeight: style?.fontSize,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      scrollPadding: scrollPadding,
      decoration: InputDecoration(
        hintText: "Your name",
        hintStyle: style?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
        errorStyle: TextStyle(color: scheme.error),
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      validator: (value) => (value ?? "").trim().isEmpty ? "Enter a name to continue." : null,
      onFieldSubmitted: (_) => onSubmitted(),
    );
  }
}

/// Creates the first rider from a name alone, written inline into an empty
/// state so it never needs a sheet or page of its own.
///
/// With a [bikeId], the new rider is also linked to that bike.
class RiderNameForm extends StatefulWidget {
  const RiderNameForm({super.key, this.bikeId});

  final String? bikeId;

  @override
  State<RiderNameForm> createState() => _RiderNameFormState();
}

class _RiderNameFormState extends State<RiderNameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _controller.text.trim();
    final bikeId = widget.bikeId;
    _focusNode.unfocus();
    unawaited(HapticFeedback.lightImpact());

    // The new rider usually replaces this form with its card before the
    // creation returns, so the confirmation is prepared while still mounted.
    final messenger = ScaffoldMessenger.of(context);
    final confirmation = AppSnackBar.success(
      context,
      bikeId == null ? "Rider '$name' created." : "Rider '$name' created and linked to this bike.",
    );

    setState(() => _saving = true);
    final person = bikeId == null
        ? await PersonActions.createRider(context, name: name)
        : await PersonActions.createRiderForBike(context, name: name, bikeId: bikeId);
    if (person != null) messenger.showSnackBar(confirmation);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Person.iconData, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              "What's your name?",
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Your rider profile tracks values like your riding weight with each setup.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            RiderNameField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_saving,
              onSubmitted: _create,
              // Keeps the button below the field above the keyboard too.
              scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: const Icon(Icons.person_add_alt),
                label: const Text("Create rider"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
