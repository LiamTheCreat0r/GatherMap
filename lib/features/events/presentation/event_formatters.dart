import 'package:flutter/material.dart';

/// Localized formatting shared by the event detail sheet.
///
/// The strings are hard-coded so the app does not depend on runtime `intl`
/// locale initialisation — the same approach the Events tab uses.

const List<String> _weekdaysShortFr = [
  'Lun.',
  'Mar.',
  'Mer.',
  'Jeu.',
  'Ven.',
  'Sam.',
  'Dim.',
];

const List<String> _weekdaysLongFr = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

const List<String> _monthsShortFr = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

const List<String> _monthsLongFr = [
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

/// Short date line for the compact sheet, e.g. `Sam. 27 sept. · 20h00`.
String formatEventShortDate(DateTime date) {
  final local = date.toLocal();
  return '${_weekdaysShortFr[local.weekday - 1]} ${local.day} '
      '${_monthsShortFr[local.month - 1]} · ${_formatTime(local)}';
}

/// Long date line for the overview card, e.g.
/// `Samedi 27 septembre 2026 à 20h00`.
String formatEventLongDate(DateTime date) {
  final local = date.toLocal();
  return '${_weekdaysLongFr[local.weekday - 1]} ${local.day} '
      '${_monthsLongFr[local.month - 1]} ${local.year} '
      'à ${_formatTime(local)}';
}

/// Whether [scheduledAt] is still ahead of [now].
bool eventIsUpcoming(DateTime scheduledAt, {DateTime? now}) =>
    scheduledAt.isAfter(now ?? DateTime.now());

/// Parses `#RRGGBB` or `#AARRGGBB`, falling back to [fallback] when the event's
/// stored colour is empty or malformed.
Color eventColorFromHex(String hex, Color fallback) {
  final cleaned = hex.trim().replaceFirst('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) return fallback;

  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;

  return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
}

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}h'
    '${date.minute.toString().padLeft(2, '0')}';
