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
  final _emojiController = TextEditingController();
  final _locationController = TextEditingController();

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
    _emojiController.text = seed.emojiIcon;
    _locationController.text = seed.location;
    _scheduledAt = seed.scheduledAt;
    _isPublic = seed.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _locationController.dispose();
    super.dispose();
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

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
                    _FieldLabel(
                      label: 'Nom',
                      textStyles: textStyles,
                      colors: colors,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      style: textStyles.bodyTextStyle.copyWith(
                        color: colors.primaryTextColor,
                      ),
                      decoration: _inputDecoration(colors, 'Apéro des voisins'),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(
                      label: 'Emoji',
                      textStyles: textStyles,
                      colors: colors,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emojiController,
                      textAlign: TextAlign.center,
                      style: textStyles.bodyTextStyle.copyWith(
                        color: colors.primaryTextColor,
                      ),
                      decoration: _inputDecoration(colors, '🎉'),
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

/// French month names, indexed by `DateTime.month - 1`.
const List<String> _monthsFrLong = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_monthsFrLong[date.month - 1]} ${date.year}';

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
