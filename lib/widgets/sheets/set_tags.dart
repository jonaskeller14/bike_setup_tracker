import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sheet.dart';

Future<Set<String>?> showSetTagsSheet({required BuildContext context, required Set<String> tags}) {
  return showModalBottomSheet(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SetTagsSheetContent(setupTags: tags.toSet());
    },
  );
}

class SetTagsSheetContent extends StatefulWidget {
  final Set<String> setupTags;

  const SetTagsSheetContent({super.key, required this.setupTags});

  @override
  State<StatefulWidget> createState() => _SetTagsSheetContentState();
}

class _SetTagsSheetContentState extends State<SetTagsSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  late Set<String> _selectedTags;
  late Set<String> _availableTags;
  
  
  @override 
  void initState() {
    super.initState();
    _selectedTags = widget.setupTags;
    _availableTags = {..._selectedTags, ...context.read<FilteredData>().setupTags};
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
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sheetTitle(context, 'Add Tags'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [                  
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      textInputAction: TextInputAction.search,
                      controller: _controller,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      maxLines: 1,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
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
                              },
                              onDeleted: _selectedTags.contains(tag)
                                  ? () => setState(() => _selectedTags.remove(tag))
                                  : null,
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _selectedTags),
              child: const Text("Confirm Selection"),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    ); 
  }
}
