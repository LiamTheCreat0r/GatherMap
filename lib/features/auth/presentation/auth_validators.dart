/// Field rules shared by the auth forms.
///
/// They live here rather than in each page so the sign-up, login and password
/// recovery screens cannot drift apart.
library;

import 'package:flutter/widgets.dart';

/// Shortest password the app accepts.
///
/// Supabase's own minimum (dashboard → Authentication → Sign In / Providers)
/// must be no lower than this, otherwise the form accepts a password the
/// server then rejects with `weak_password`.
const int kMinPasswordLength = 6;

/// Matches anything with a local part, an `@` and a dotted domain. Email
/// validation belongs on the server; this only catches obvious typos before a
/// round trip.
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Usernames are lowercase letters, digits, dot and underscore, 3 to 20 long.
final RegExp _usernamePattern = RegExp(r'^[a-z0-9._]{3,20}$');

/// Requires a non-empty value.
String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) return 'Champ obligatoire.';
  return null;
}

/// Requires a plausible email address.
String? validateEmail(String? value) {
  final required = validateRequired(value);
  if (required != null) return required;
  if (!_emailPattern.hasMatch(value!.trim())) {
    return 'Adresse e-mail invalide.';
  }
  return null;
}

/// Requires at least [kMinPasswordLength] characters.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Champ obligatoire.';
  if (value.length < kMinPasswordLength) {
    return 'Au moins $kMinPasswordLength caractères.';
  }
  return null;
}

/// Requires [other] to match.
String? Function(String?) validatePasswordConfirmation(
  TextEditingController other,
) {
  return (String? value) {
    if (value != other.text) return 'Les mots de passe ne correspondent pas.';
    return null;
  };
}

/// Requires a username matching [_usernamePattern].
String? validateUsername(String? value) {
  final required = validateRequired(value);
  if (required != null) return required;
  if (!_usernamePattern.hasMatch(value!.trim())) {
    return '3 à 20 caractères, minuscules, chiffres, point ou tiret bas.';
  }
  return null;
}
