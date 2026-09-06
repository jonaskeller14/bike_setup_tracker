import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../utils/person_actions.dart';
import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

/// Asks for the one thing a rider profile needs to be useful: a name.
///
/// The slide never names the internal Person feature, and it never collects a
/// riding weight — only its definition is created, so the first setup is where
/// a value is entered.
class OnboardingSlide5 extends StatefulWidget {
  const OnboardingSlide5({
    super.key,
    required this.onNext,
    required this.active,
    required this.controller,
    required this.savedName,
    required this.onSaved,
  });

  final VoidCallback onNext;

  /// True once this is the settled page. The field takes focus then — never
  /// while the slide is only built as the neighbour of another one, which
  /// would raise the keyboard over a slide the rider is still reading.
  final bool active;

  /// Owned by the page, so the typed name survives a swipe or Back.
  final TextEditingController controller;

  /// The rider already created in this session, if any. Set, the slide only
  /// confirms it — saving twice would create a second rider.
  final String? savedName;
  final ValueChanged<String> onSaved;

  @override
  State<OnboardingSlide5> createState() => _OnboardingSlide5State();
}

class _OnboardingSlide5State extends State<OnboardingSlide5> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();

  bool _saving = false;

  @override
  void didUpdateWidget(covariant OnboardingSlide5 oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _syncFocus() {
    if (widget.active && widget.savedName == null) {
      _focusNode.requestFocus();
    } else if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = widget.controller.text.trim();
    _focusNode.unfocus();

    setState(() => _saving = true);
    final person = await PersonActions.createOnboardingRider(context, name: name);
    if (!mounted) return;
    setState(() => _saving = false);
    if (person == null) return;

    widget.onSaved(person.name);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final savedName = widget.savedName;

    return OnboardingSlideScaffold(
      onNext: savedName != null ? widget.onNext : _save,
      nextLabel: savedName != null ? "Next" : "Continue",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DelayedFade(
            delay: Duration.zero,
            child: Icon(Person.iconData, size: 120),
          ),
          const SizedBox(height: 60),
          Text(
            "What's your name?",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "You can change it any time.",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (savedName != null) _SavedRider(name: savedName) else _nameField(context),
        ],
      ),
    );
  }

  Widget _nameField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A single line to write on rather than a boxed form field: this is the one
    // thing the slide asks for, so it gets the weight of a headline.
    final style = Theme.of(context).textTheme.headlineSmall;

    return Form(
      key: _formKey,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: !_saving,
        textAlign: TextAlign.center,
        style: style,
        cursorHeight: style?.fontSize,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
        onFieldSubmitted: (_) => _save(),
      ),
    );
  }
}

/// The one place the entered name is echoed back.
class _SavedRider extends StatelessWidget {
  const _SavedRider({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              "Nice to meet you, $name!",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSecondaryContainer),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
