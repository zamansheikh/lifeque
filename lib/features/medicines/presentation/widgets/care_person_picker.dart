import 'package:flutter/material.dart';

import '../../../../injection_container.dart' as di;
import '../../../../l10n/app_localizations.dart';
import '../../data/services/care_person_service.dart';
import '../../domain/entities/care_person.dart';

/// The round initial that stands in for a person everywhere they appear.
class CarePersonAvatar extends StatelessWidget {
  const CarePersonAvatar({super.key, required this.person, this.size = 28});

  final CarePerson person;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: person.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        person.initial,
        style: TextStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w800,
          color: person.color,
        ),
      ),
    );
  }
}

/// A row of people to choose between, with "add" on the end.
///
/// Used on the medicine form to say who a course is for. The dashboard uses
/// [CarePersonFilterBar] instead, which is the same idea plus an "everyone".
class CarePersonSelector extends StatefulWidget {
  const CarePersonSelector({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  State<CarePersonSelector> createState() => _CarePersonSelectorState();
}

class _CarePersonSelectorState extends State<CarePersonSelector> {
  final _service = di.sl<CarePersonService>();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final people = _service.getAll();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.medPerson,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (people.isEmpty)
          Text(
            l.medNoPeopleYet,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        if (people.isEmpty) const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final person in people)
              _PersonChip(
                person: person,
                selected: person.id == widget.selectedId,
                onTap: () => widget.onChanged(
                  person.id == widget.selectedId ? null : person.id,
                ),
                onLongPress: () => _manage(person),
              ),
            _AddChip(onTap: _addPerson),
          ],
        ),
      ],
    );
  }

  Future<void> _addPerson() async {
    final name = await promptForPersonName(context);
    if (name == null || name.trim().isEmpty) return;
    final person = await _service.add(name);
    if (!mounted) return;
    setState(() {});
    // Selecting what was just added is almost always what is wanted, and
    // saves a second tap.
    widget.onChanged(person.id);
  }

  Future<void> _manage(CarePerson person) async {
    final action = await showPersonActions(context, person);
    if (action == null || !mounted) return;
    if (action == CarePersonAction.rename) {
      final name = await promptForPersonName(context, initial: person.name);
      if (name == null || name.trim().isEmpty) return;
      await _service.rename(person.id, name);
    } else {
      await _service.remove(person.id);
      if (widget.selectedId == person.id) widget.onChanged(null);
    }
    if (mounted) setState(() {});
  }
}

/// Filter chips for the dashboard: everyone, then one per person.
class CarePersonFilterBar extends StatelessWidget {
  const CarePersonFilterBar({
    super.key,
    required this.people,
    required this.selectedId,
    required this.onChanged,
  });

  final List<CarePerson> people;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // One person is not a choice, so the bar only earns its space from two.
    if (people.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: L.of(context).medPersonEveryone,
            color: const Color(0xFF3B82F6),
            selected: selectedId == null,
            onTap: () => onChanged(null),
          ),
          for (final person in people) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: person.name,
              color: person.color,
              selected: person.id == selectedId,
              onTap: () => onChanged(person.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.person,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final CarePerson person;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? person.color.withValues(alpha: 0.16)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? person.color : const Color(0xFFE2E8F0),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarePersonAvatar(person: person, size: 24),
              const SizedBox(width: 8),
              Text(
                person.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? person.color : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Text(
                L.of(context).medAddPerson,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum CarePersonAction { rename, remove }

Future<String?> promptForPersonName(
  BuildContext context, {
  String? initial,
}) async {
  final controller = TextEditingController(text: initial ?? '');
  final l = L.of(context);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(initial == null ? l.medAddPerson : l.medPersonRename),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l.medPersonName,
          hintText: l.medPersonNameHint,
        ),
        onSubmitted: (value) => Navigator.pop(dialogContext, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l.permCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(l.commonSave),
        ),
      ],
    ),
  );
}

Future<CarePersonAction?> showPersonActions(
  BuildContext context,
  CarePerson person,
) {
  final l = L.of(context);
  return showModalBottomSheet<CarePersonAction>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CarePersonAvatar(person: person),
            title: Text(
              person.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: Text(l.medPersonRename),
            onTap: () => Navigator.pop(sheetContext, CarePersonAction.rename),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_remove_rounded,
              color: Color(0xFFDC2626),
            ),
            title: Text(l.medPersonRemove),
            subtitle: Text(
              l.medPersonRemoveBody,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => Navigator.pop(sheetContext, CarePersonAction.remove),
          ),
        ],
      ),
    ),
  );
}
