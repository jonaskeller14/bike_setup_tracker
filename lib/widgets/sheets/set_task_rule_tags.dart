import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import 'sheet_header.dart';

Future<void> showSetTaskRuleTagsSheet({
  required BuildContext context, 
  required Set<String> tags,
  required ValueChanged<Set<String>> onChanged,
}) {
  return showModalBottomSheet(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SetTaskRuleTagsSheetContent(
        taskRuleTags: tags.toSet(),
        onChanged: onChanged,
      );
    },
  );
}

class SetTaskRuleTagsSheetContent extends StatefulWidget {
  final Set<String> taskRuleTags;
  final ValueChanged<Set<String>> onChanged;

  const SetTaskRuleTagsSheetContent({
    super.key, 
    required this.taskRuleTags,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => _SetTaskRuleTagsSheetContentState();
}

class _SetTaskRuleTagsSheetContentState extends State<SetTaskRuleTagsSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  late Set<String> _selectedTags;
  late Set<String> _availableTags;
  
  
  @override 
  void initState() {
    super.initState();
    _selectedTags = widget.taskRuleTags;
    _availableTags = {..._selectedTags, ...context.read<AppRepository>().taskRuleTags};
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _addTag() {
    if (!_formKey.currentState!.validate()) return;

    final newTag = _controller.text.trim();

    FocusScope.of(context).unfocus();

    setState(() {
      _availableTags.add(newTag);
      _selectedTags.add(newTag);

      _controller.clear();
      _formKey.currentState!.reset();
      _controller.text = "";
    });
    widget.onChanged(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Add Tags'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Use tags to group and organize your tasks (e.g. maintenance, order list, setup test, ...)"),
            dense: true,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [                  
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      textInputAction: TextInputAction.done,
                      controller: _controller,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      maxLines: 1,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        labelText: "Add new tag",
                        hintText: 'New Tag',
                        contentPadding: const EdgeInsets.all(8),
                        icon: const Icon(Icons.tag),
                        suffixIcon: IconButton(
                          onPressed: _addTag,
                          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      validator: (String? newValue) {
                        if (newValue == null || newValue.trim().isEmpty) return "Empty tag is not allowed";
                        if (_availableTags.contains(newValue.trim())) return "Tag already exists";
                        return null;
                      },
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _availableTags.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text("No tags yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          children: _availableTags.map((tag) {
                            return FilterChip(
                              avatar: const Icon(Icons.tag),
                              label: Text(tag),
                              selected: _selectedTags.contains(tag),
                              showCheckmark: false,
                                onSelected: (bool newValue) {
                                  switch (newValue) {
                                    case true: setState(() => _selectedTags.add(tag));
                                    case false: setState(() => _selectedTags.remove(tag));
                                  }
                                  widget.onChanged(_selectedTags);
                                },
                                onDeleted: _selectedTags.contains(tag)
                                    ? () {
                                        setState(() => _selectedTags.remove(tag));
                                        widget.onChanged(_selectedTags);
                                      }
                                    : null,
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    ); 
  }
}
