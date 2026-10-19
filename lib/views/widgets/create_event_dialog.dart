import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/event_controller.dart';
import '../../core/theme/custom_colors.dart';
import '../../core/theme/custom_text_styles.dart';
import '../../models/event.dart';
import '../../services/address_service.dart';

/// Opens the create-event window floating over the current screen.
///
/// The window is a rounded card that covers only part of the map behind it;
/// dismissing it (tap outside, the close button, or a footer action) returns to
/// the map untouched. Resolves with the [Event] that was inserted, or `null`
/// when the window was dismissed without creating one.
Future<Event?> showCreateEventDialog(BuildContext context) {
  return showDialog<Event>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const CreateEventDialog(),
  );
}

/// Floating, rounded create-event form shown over the map.
///
/// The form starts blank and every field is required: submitting validates
/// them inline and, when complete, inserts the event through [EventController]
/// and pops with the created row. Colours and text styles come from the
/// [CustomColors] and [CustomTextStyles] theme extensions, so light and dark
/// mode are handled by the active theme with no branching here.
class CreateEventDialog extends StatefulWidget {
  const CreateEventDialog({super.key});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _nameController = TextEditingController();

  /// Selected event icon; empty means none chosen yet.
  String _emoji = '';

  /// Address chosen from the autocomplete (or typed freely).
  String _location = '';

  /// Coordinates of the chosen address, from the geocoder. Null when the
  /// location was typed freely (no suggestion picked) — such events are
  /// created without a map position and simply aren't pinned.
  double? _latitude;
  double? _longitude;

  /// Chosen date and time; null until the organiser picks one.
  DateTime? _scheduledAt;

  /// New events are private unless the organiser opts into a public one.
  bool _isPublic = false;

  /// True while the insert is in flight; disables the footer buttons.
  bool _isSubmitting = false;

  /// Per-field validation messages, set on submit and cleared as fields fill.
  String? _nameError;
  String? _dateError;
  String? _locationError;
  String? _emojiError;

  /// Message shown when the insert itself fails.
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
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
    setState(() {
      _emoji = picked;
      _emojiError = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      final base = _scheduledAt ?? DateTime.now();
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _pickTime() async {
    final base = _scheduledAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
      _dateError = null;
    });
  }

  /// Validates the form and, when complete, inserts the event.
  Future<void> _onCreate() async {
    final name = _nameController.text.trim();
    final location = _location.trim();

    final nameMissing = name.isEmpty;
    final dateMissing = _scheduledAt == null;
    final locationMissing = location.isEmpty;
    final emojiMissing = _emoji.isEmpty;

    setState(() {
      _nameError = nameMissing ? 'Le nom est requis.' : null;
      _dateError = dateMissing ? 'La date et l\'heure sont requises.' : null;
      _locationError = locationMissing ? 'Le lieu est requis.' : null;
      _emojiError = emojiMissing ? 'Choisissez une icône.' : null;
    });

    if (nameMissing || dateMissing || locationMissing || emojiMissing) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final controller = context.read<EventController>();
    // The organiser is whoever is signed in; the `event_insert_own` policy
    // refuses any other value. Reaching this dialog at all means the gate found
    // a session, so the id is present.
    final ownerId = context.read<AuthController>().userId;
    if (ownerId == null) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Session expirée, reconnectez-vous.';
      });
      return;
    }

    final created = await controller.create(
      ownerId: ownerId,
      scheduledAt: _scheduledAt!,
      location: location,
      name: name,
      emojiIcon: _emoji,
      isPublic: _isPublic,
      latitude: _latitude,
      longitude: _longitude,
    );

    if (!mounted) return;
    if (created == null) {
      setState(() {
        _isSubmitting = false;
        _submitError = controller.error ?? 'La création a échoué.';
      });
      return;
    }

    Navigator.pop(context, created);
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
                                onChanged: (_) {
                                  if (_nameError != null) {
                                    setState(() => _nameError = null);
                                  }
                                },
                                decoration: _inputDecoration(
                                  colors,
                                  'Apéro des voisins',
                                ).copyWith(errorText: _nameError),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Small square, bottom-aligned with the name input,
                        // holding the event's emoji icon.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _EmojiField(
                              emoji: _emoji,
                              colors: colors,
                              onTap: _pickEmoji,
                            ),
                            if (_emojiError != null) ...[
                              const SizedBox(height: 4),
                              _FieldError(message: _emojiError!),
                            ],
                          ],
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
                            label: _scheduledAt == null
                                ? 'Date'
                                : _formatDate(_scheduledAt!),
                            colors: colors,
                            textStyles: textStyles,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerField(
                            icon: Icons.schedule_outlined,
                            label: _scheduledAt == null
                                ? 'Heure'
                                : _formatTime(_scheduledAt!),
                            colors: colors,
                            textStyles: textStyles,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    if (_dateError != null) ...[
                      const SizedBox(height: 4),
                      _FieldError(message: _dateError!),
                    ],
                    const SizedBox(height: 16),
                    _FieldLabel(
                      label: 'Lieu',
                      textStyles: textStyles,
                      colors: colors,
                    ),
                    const SizedBox(height: 6),
                    _AddressField(
                      initialValue: _location,
                      colors: colors,
                      textStyles: textStyles,
                      onChanged: (value) {
                        // Free typing invalidates any previously picked
                        // coordinates: the new text has no known position.
                        _location = value;
                        _latitude = null;
                        _longitude = null;
                        if (_locationError != null) {
                          setState(() => _locationError = null);
                        }
                      },
                      onSuggestionSelected: (suggestion) {
                        _location = suggestion.placeName;
                        _latitude = suggestion.latitude;
                        _longitude = suggestion.longitude;
                        if (_locationError != null) {
                          setState(() => _locationError = null);
                        }
                      },
                    ),
                    if (_locationError != null) ...[
                      const SizedBox(height: 4),
                      _FieldError(message: _locationError!),
                    ],
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
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: _FieldError(message: _submitError!),
              ),
            _Footer(
              colors: colors,
              textStyles: textStyles,
              isSubmitting: _isSubmitting,
              onCancel: () => Navigator.pop(context),
              onCreate: _onCreate,
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

/// Inline validation/error caption shown under a field.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;

    return Text(
      message,
      style: textStyles.labelStyle.copyWith(color: colors.dangerColor),
    );
  }
}

/// Address input with live autocomplete backed by [AddressService].
///
/// Typing triggers a debounced geocoding lookup; tapping a suggestion fills the
/// field with its full label. Free text is still allowed if the user does not
/// pick a suggestion.
class _AddressField extends StatefulWidget {
  const _AddressField({
    required this.initialValue,
    required this.colors,
    required this.textStyles,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  final String initialValue;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  /// Fires on free typing, with just the raw text — no coordinates.
  final ValueChanged<String> onChanged;

  /// Fires when the user picks a geocoded suggestion, carrying its label and
  /// coordinates.
  final ValueChanged<AddressSuggestion> onSuggestionSelected;

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  final AddressService _service = AddressService();

  /// Incremented per keystroke; a lookup whose token is stale is discarded.
  int _queryToken = 0;

  Future<List<AddressSuggestion>> _search(String query) async {
    final token = ++_queryToken;

    // Debounce so a burst of keystrokes issues a single request.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (token != _queryToken) return const [];

    try {
      return await _service.search(query);
    } on Object {
      // A failed lookup just shows no suggestions; the user can still type.
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<AddressSuggestion>(
      initialValue: TextEditingValue(text: widget.initialValue),
      optionsBuilder: (value) {
        final query = value.text.trim();
        if (query.length < 3) return const <AddressSuggestion>[];
        return _search(query);
      },
      displayStringForOption: (option) => option.placeName,
      onSelected: (option) {
        widget.onChanged(option.placeName);
        widget.onSuggestionSelected(option);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          style: widget.textStyles.bodyTextStyle.copyWith(
            color: widget.colors.primaryTextColor,
          ),
          decoration: _inputDecoration(
            widget.colors,
            'Café de la Gare',
          ).copyWith(
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: widget.colors.secondaryTextColor,
            ),
          ),
          onChanged: widget.onChanged,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: widget.colors.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: widget.colors.borderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 380),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text(
                        option.placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: widget.textStyles.bodyTextStyle.copyWith(
                          color: widget.colors.primaryTextColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Curated set of event/party emojis offered by the picker.
///
/// Kept small and hand-picked so the grid stays on-theme and needs no extra
/// dependency or search UI.
const List<String> _eventEmojis = [
  '🎉',
  '🍻',
  '🎂',
  '🍕',
  '🍽️',
  '☕',
  '🎵',
  '🎸',
  '🎮',
  '🎳',
  '🎨',
  '🎬',
  '⚽',
  '🏀',
  '🚴',
  '🏖️',
  '🌳',
  '🏕️',
  '📸',
  '🎯',
  '🍿',
  '🥂',
  '🏠',
  '🚀',
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
    required this.isSubmitting,
    required this.onCancel,
    required this.onCreate,
  });

  final CustomColors colors;
  final CustomTextStyles textStyles;

  /// While true the create button shows a spinner and both buttons are inert.
  final bool isSubmitting;
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
              onPressed: isSubmitting ? null : onCancel,
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
              onPressed: isSubmitting ? null : onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Créer',
                      style: textStyles.actionStyle.copyWith(
                        color: Colors.white,
                      ),
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
