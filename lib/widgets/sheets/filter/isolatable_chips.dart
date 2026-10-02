import 'package:flutter/material.dart';

class IsolatableChipOption {
  const IsolatableChipOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
}

/// Filter chips where a long-press selects only that option, or every option
/// again when it already is the only one selected.
class IsolatableChips extends StatelessWidget {
  final List<IsolatableChipOption> options;

  const IsolatableChips({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: List.generate(options.length, (index) {
        final option = options[index];
        return GestureDetector(
          onLongPress: options.length < 2
              ? null
              : () {
                  final isIsolated = option.selected && options.where((o) => o.selected).length == 1;
                  for (var i = 0; i < options.length; i++) {
                    options[i].onChanged(isIsolated ? true : i == index);
                  }
                },
          child: FilterChip(
            avatar: option.icon == null ? null : Icon(option.icon),
            label: Text(option.label),
            showCheckmark: false,
            selected: option.selected,
            onSelected: option.onChanged,
            onDeleted: option.selected ? () => option.onChanged(false) : null,
          ),
        );
      }),
    );
  }
}

Set<T> toggled<T>(Set<T> values, T value, {required bool selected}) =>
    selected ? {...values, value} : values.difference({value});
