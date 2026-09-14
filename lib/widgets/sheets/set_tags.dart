import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import 'add_tag_chip.dart';
import 'sheet_header.dart';

Future<void> showSetTagsSheet({
  required BuildContext context, 
  required Set<String> tags,
  required ValueChanged<Set<String>> onChanged,
  required String title,
  required String subtitle,
}) {
  return showModalBottomSheet(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return SetTagsSheetContent(
        setupTags: tags.toSet(),
        onChanged: onChanged,
        title: title,
        subtitle: subtitle,
      );
    },
  );
}

class SetTagsSheetContent extends StatefulWidget {
  final Set<String> setupTags;
  final ValueChanged<Set<String>> onChanged;
  final String title;
  final String subtitle;

  const SetTagsSheetContent({
    super.key, 
    required this.setupTags,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  State<StatefulWidget> createState() => _SetTagsSheetContentState();
}

class _SetTagsSheetContentState extends State<SetTagsSheetContent> {
  late Set<String> _selectedTags;
  late Set<String> _availableTags;
  late bool _addingTag;

  @override 
  void initState() {
    super.initState();
    _selectedTags = widget.setupTags;
    _availableTags = {..._selectedTags, ...context.read<AppRepository>().setupTags};
    // With nothing to pick from, the sheet opens straight into the new-tag field.
    _addingTag = _availableTags.isEmpty;
  }

  String? _addTag(String newTag) {
    if (_availableTags.contains(newTag)) return "Tag already exists";

    setState(() {
      _availableTags.add(newTag);
      _selectedTags.add(newTag);
    });
    widget.onChanged(_selectedTags);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: widget.title),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(widget.subtitle),
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
                  if (_availableTags.isEmpty && !_addingTag)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text("No tags yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                      ),
                    ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._availableTags.map((tag) {
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
                      }),
                      AddTagChip(
                        autofocus: _availableTags.isEmpty,
                        prominent: _availableTags.isEmpty,
                        onEditingChanged: (editing) => setState(() => _addingTag = editing),
                        onSubmit: _addTag,
                      ),
                    ],
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
