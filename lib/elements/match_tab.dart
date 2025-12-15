import 'package:flutter/material.dart';

/// Usage:
/// MatchCategoryTabs(
///   onChanged: (value) {
///     // value = 'ALL' / 'CRICKET' / 'FOOTBALL'
///   },
/// )
class MatchCategoryTabs extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final String initial;

  const MatchCategoryTabs({
    super.key,
    this.onChanged,
    this.initial = 'ALL',
  });

  @override
  State<MatchCategoryTabs> createState() => _MatchCategoryTabsState();
}

class _MatchCategoryTabsState extends State<MatchCategoryTabs> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toUpperCase();
  }

  void _onTap(String value) {
    setState(() {
      _selected = value;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['ALL', 'CRICKET', 'FOOTBALL'];

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 10, left: 16, right: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: tabs.map((label) {
          final bool isSelected = _selected == label;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onTap(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF4C5B) // red active pill
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white :Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
