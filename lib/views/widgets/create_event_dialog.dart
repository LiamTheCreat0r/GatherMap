import 'package:flutter/material.dart';

import '../../core/theme/custom_colors.dart';
import '../../core/theme/custom_text_styles.dart';
import '../../models/event.dart';

/// Opens the create-event window floating over the current screen.
///
/// The window is a rounded card that covers only part of the map behind it;
/// dismissing it (tap outside, the close button, or a footer action) returns to
/// the map untouched.
Future<void> showCreateEventDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const CreateEventDialog(),
  );
}

/// Floating, rounded create-event form shown over the map.
///
/// This is UI scaffolding only: the fields are seeded from a placeholder
/// [Event] and nothing is saved yet. Colours and text styles come from the
/// [CustomColors] and [CustomTextStyles] theme extensions, so light and dark
/// mode are handled by the active theme with no branching here.
class CreateEventDialog extends StatefulWidget {
  const CreateEventDialog({super.key});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  /// Selected event icon; empty means none chosen yet.
  String _emoji = '🎉';
  late DateTime _scheduledAt;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    // Seed the fields from a throwaway row so the form matches the Event model.
    // The controller is not involved yet.
    final seed = Event(
      id: null,
      ownerId: '',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      location: '',
      createdAt: null,
      name: '',
      emojiIcon: '🎉',
      color: '',
      isPublic: true,
    );

    _nameController.text = seed.name;
    _emoji = seed.emojiIcon;
    _locationController.text = seed.location;
    _scheduledAt = seed.scheduledAt;
    _isPublic = seed.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Opens the emoji grid and stores the picked icon, if any.
  Future<void> _pickEmoji() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmojiPickerSheet(current: _emoji),
    );
    if (picked == null) return;
    setState(() => _emoji = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;

    // Keep the window clear of the screen edges so the map stays visible behind
    // it, and cap its height so long content scrolls instead of filling up.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: colors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.borderColor, width: 1),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              title: 'Créer un événement',
              colors: colors,
              textStyles: textStyles,
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(
                                label: 'Nom',
                                textStyles: textStyles,
                                colors: colors,
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _nameController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: textStyles.bodyTextStyle.copyWith(
                                  color: colors.primaryTextColor,
                                ),
                                decoration: _inputDecoration(
                                  colors,
                                  'Apéro des voisins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Small square, bottom-aligned with the name input,
                        // holding the event's emoji icon.
                        _EmojiField(
                          emoji: _emoji,
                          colors: colors,
                          onTap: _pickEmoji,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(
                      label: 'Date et heure',
                      textStyles: textStyles,
                      colors: colors,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerField(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(_scheduledAt),
                            colors: colors,
                            textStyles: textStyles,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerField(
                            icon: Icons.schedule_outlined,
                            label: _formatTime(_scheduledAt),
                            colors: colors,
                            textStyles: textStyles,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(
                      label: 'Lieu',
                      textStyles: textStyles,
                      colors: colors,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      style: textStyles.bodyTextStyle.copyWith(
                        color: colors.primaryTextColor,
                      ),
                      decoration: _inputDecoration(colors, 'Café de la Gare'),
                    ),
                    const SizedBox(height: 12),
                    _PublicToggle(
                      value: _isPublic,
                      colors: colors,
                      textStyles: textStyles,
                      onChanged: (value) => setState(() => _isPublic = value),
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              colors: colors,
              textStyles: textStyles,
              onCancel: () => Navigator.pop(context),
              // Not wired to the controller yet: closes the window for now.
              onCreate: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded, filled input decoration shared by the dialog's text fields.
InputDecoration _inputDecoration(CustomColors colors, String hint) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colors.borderColor, width: 1),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: colors.secondaryTextColor),
    filled: true,
    fillColor: colors.secondarySurfaceColor,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: colors.accentColor, width: 1.5),
    ),
  );
}

/// Fixed header row: title on the left, close button on the right.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.colors,
    required this.textStyles,
    required this.onClose,
  });

  final String title;
  final CustomColors colors;
  final CustomTextStyles textStyles;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textStyles.subTitleStyle.copyWith(
                color: colors.primaryTextColor,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: colors.secondaryTextColor,
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }
}

/// Small uppercase-ish caption above each field.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.textStyles,
    required this.colors,
  });

  final String label;
  final CustomTextStyles textStyles;
  final CustomColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textStyles.labelStyle.copyWith(color: colors.secondaryTextColor),
    );
  }
}

/// Curated set of event/party emojis offered by the picker.
///
/// Kept small and hand-picked so the grid stays on-theme and needs no extra
/// dependency or search UI.
const List<String> _eventEmojis = [
  '🎉', '🍻', '🎂', '🍕', '🍽️', '☕',
  '🎵', '🎸', '🎮', '🎳', '🎨', '🎬',
  '⚽', '🏀', '🚴', '🏖️', '🌳', '🏕️',
  '📸', '🎯', '🍿', '🥂', '🏠', '🚀',
];

/// Tappable 52px square showing the event's icon; opens the emoji grid.
class _EmojiField extends StatelessWidget {
  const _EmojiField({
    required this.emoji,
    required this.colors,
    required this.onTap,
  });

  /// Currently selected emoji, or an empty string for none.
  final String emoji;
  final CustomColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Choisir une icône',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondarySurfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderColor, width: 1),
          ),
          child: emoji.isEmpty
              ? Icon(
                  Icons.emoji_emotions_outlined,
                  size: 22,
                  color: colors.secondaryTextColor,
                )
              : Text(emoji, style: const TextStyle(fontSize: 22, height: 1.2)),
        ),
      ),
    );
  }
}

/// Rounded bottom sheet holding the [_eventEmojis] grid.
///
/// Pops with the tapped emoji, or `null` when dismissed.
class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.current});

  /// Currently selected emoji, highlighted in the grid.
  final String current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: colors.borderColor, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choisir une icône',
              style: textStyles.subTitleStyle.copyWith(
                color: colors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final emoji in _eventEmojis)
                    _EmojiTile(
                      emoji: emoji,
                      isSelected: emoji == current,
                      colors: colors,
                      onTap: () => Navigator.pop(context, emoji),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One emoji cell: a rounded tile that highlights the current selection.
class _EmojiTile extends StatelessWidget {
  const _EmojiTile({
    required this.emoji,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final CustomColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondarySurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accentColor : colors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22, height: 1.2)),
      ),
    );
  }
}

/// Tappable field that opens a date or time picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.colors,
    required this.textStyles,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final CustomColors colors;
  final CustomTextStyles textStyles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.secondarySurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.secondaryTextColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyles.bodyTextStyle.copyWith(
                  color: colors.primaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Public/private switch mapped to the model's `isPublic` flag.
class _PublicToggle extends StatelessWidget {
  const _PublicToggle({
    required this.value,
    required this.colors,
    required this.textStyles,
    required this.onChanged,
  });

  final bool value;
  final CustomColors colors;
  final CustomTextStyles textStyles;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          value ? Icons.public : Icons.lock_outline,
          size: 18,
          color: colors.secondaryTextColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ? 'Événement public' : 'Événement privé',
            style: textStyles.bodyTextStyle.copyWith(
              color: colors.primaryTextColor,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.accentColor,
        ),
      ],
    );
  }
}

/// Bottom action row: cancel and create.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.colors,
    required this.textStyles,
    required this.onCancel,
    required this.onCreate,
  });

  final CustomColors colors;
  final CustomTextStyles textStyles;
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryTextColor,
                side: BorderSide(color: colors.borderColor, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Annuler',
                style: textStyles.actionStyle.copyWith(
                  color: colors.primaryTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Créer',
                style: textStyles.actionStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Short French date, e.g. `16/10/2026`.
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
