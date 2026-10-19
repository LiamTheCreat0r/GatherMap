import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_themes.dart';
import '../auth/auth_validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/page_header.dart';

/// Three-step profile completion, shown once per new account.
///
/// It collects what sign-up could not: a unique username, the birth date, the
/// city and the privacy preference. The answers are held in this widget and
/// written in one go by [ProfileController.completeOnboarding], so backing out
/// half-way leaves nothing behind — and the gate replaces this screen with the
/// app as soon as the profile comes back marked complete.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const int _stepCount = 3;

  final _pageController = PageController();
  final _identityKey = GlobalKey<FormState>();
  final _locationKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();

  DateTime? _birthdate;
  bool _privateAccount = false;
  int _step = 0;

  /// Failure to show under the current step: a taken username, a failed
  /// availability check, or a refused save.
  String? _error;

  /// True while a request started by this screen is in flight.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The trigger already copied the names out of the sign-up metadata.
    final profile = context.read<ProfileController>().current;
    _nameController.text = profile?.name ?? '';
    _surnameController.text = profile?.surname ?? '';
    _cityController.text = profile?.city ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _birthdate = picked;
      _error = null;
    });
  }

  /// Validates the current step, checks the username on the first one, then
  /// advances.
  Future<void> _next() async {
    if (_step == 0) {
      if (!(_identityKey.currentState?.validate() ?? false)) return;
      FocusScope.of(context).unfocus();

      setState(() {
        _busy = true;
        _error = null;
      });
      final profiles = context.read<ProfileController>();
      final available = await profiles.isUsernameAvailable(
        _usernameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (profiles.hasError) {
        setState(() => _error = profiles.error);
        return;
      }
      if (!available) {
        setState(() => _error = 'Ce pseudo est déjà pris.');
        return;
      }
    } else if (_step == 1) {
      if (!(_locationKey.currentState?.validate() ?? false)) return;
      if (_birthdate == null) {
        setState(() => _error = 'Indiquez votre date de naissance.');
        return;
      }
      FocusScope.of(context).unfocus();
    }

    await _goTo(_step + 1);
  }

  Future<void> _back() => _goTo(_step - 1);

  Future<void> _goTo(int step) async {
    setState(() {
      _step = step;
      _error = null;
    });
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final birthdate = _birthdate;
    if (birthdate == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final profiles = context.read<ProfileController>();
    final profile = await profiles.completeOnboarding(
      username: _usernameController.text.trim(),
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      birthdate: birthdate,
      city: _cityController.text.trim(),
      privateAccount: _privateAccount,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (profile != null) return; // The gate takes over from here.

    final error = profiles.error ?? '';
    setState(() {
      _error = error.contains('23505')
          ? 'Ce pseudo vient d\'être pris.'
          : (error.isEmpty ? 'Enregistrement impossible.' : error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          PageHeader(
            title: 'Mon profil',
            trailing: IconButton(
              onPressed: () => context.read<AuthController>().signOut(),
              tooltip: 'Se déconnecter',
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
          LinearProgressIndicator(
            value: (_step + 1) / _stepCount,
            minHeight: 4,
            color: colors.accentColor,
            backgroundColor: colors.discreetBackgroundColor,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _identityStep(),
                _locationStep(),
                _privacyStep(),
              ],
            ),
          ),
          _footer(auth),
        ],
      ),
    );
  }

  Widget _identityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Form(
        key: _identityKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepIntro(
              'Faisons connaissance',
              'Votre nom et un pseudo unique pour vous retrouver entre amis.',
            ),
            AppTextField(
              controller: _nameController,
              label: 'Prénom',
              textInputAction: TextInputAction.next,
              validator: validateRequired,
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _surnameController,
              label: 'Nom',
              textInputAction: TextInputAction.next,
              validator: validateRequired,
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _usernameController,
              label: 'Pseudo',
              hint: 'camille_d',
              textInputAction: TextInputAction.done,
              validator: validateUsername,
              enabled: !_busy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Form(
        key: _locationKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepIntro(
              'Où et quand ?',
              'Votre ville sert à proposer les événements proches de vous.',
            ),
            AppTextField(
              controller: _cityController,
              label: 'Ville',
              textInputAction: TextInputAction.done,
              validator: validateRequired,
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            _DateField(
              value: _birthdate,
              enabled: !_busy,
              onTap: _pickBirthdate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyStep() {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepIntro(
            'Dernière étape',
            'Vous pourrez changer tout cela plus tard depuis votre compte.',
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor),
            ),
            child: SwitchListTile(
              value: _privateAccount,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _privateAccount = value),
              activeThumbColor: colors.accentColor,
              title: Text(
                'Compte privé',
                style: textStyles.subTitleStyle.copyWith(
                  color: colors.primaryTextColor,
                ),
              ),
              subtitle: Text(
                'Seuls vos amis voient vos événements privés et vos apparitions '
                'sur la carte.',
                style: textStyles.bodyTextStyle.copyWith(
                  color: colors.secondaryTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _summary(),
        ],
      ),
    );
  }

  /// Recap of the answers, so the last step is not a blind tap on "Terminer".
  Widget _summary() {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final rows = <(String, String)>[
      ('Pseudo', '@${_usernameController.text.trim()}'),
      ('Nom', '${_nameController.text.trim()} ${_surnameController.text.trim()}'),
      ('Ville', _cityController.text.trim()),
      ('Naissance', _formatDate(_birthdate)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: textStyles.labelStyle.copyWith(
                      color: colors.secondaryTextColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: textStyles.bodyTextStyle.copyWith(
                      color: colors.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _footer(AuthController auth) {
    final colors = context.colors;
    final isLast = _step == _stepCount - 1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppErrorText(message: _error),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_step > 0) ...[
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Retour',
                      isLoading: false,
                      onPressed: _busy ? null : _back,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    label: isLast ? 'Terminer' : 'Suivant',
                    isLoading: _busy,
                    onPressed: isLast ? _finish : _next,
                  ),
                ),
              ],
            ),
            if (auth.email != null) ...[
              const SizedBox(height: 12),
              Text(
                'Connecté en tant que ${auth.email}',
                textAlign: TextAlign.center,
                style: context.textStyles.legendStyle.copyWith(
                  color: colors.secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepIntro(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textStyles.mainTitleStyle.copyWith(
              color: context.colors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: context.textStyles.bodyTextStyle.copyWith(
              color: context.colors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable field that opens the date picker, styled like [AppTextField].
///
/// A form field would validate an empty string; a birth date is picked, not
/// typed, so the value is checked by the step itself.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onTap,
    required this.enabled,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final filled = value != null;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          filled: true,
          fillColor: colors.cardColor,
          labelStyle: textStyles.bodyTextStyle.copyWith(
            color: colors.secondaryTextColor,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: _border(colors.borderColor),
          enabledBorder: _border(colors.borderColor),
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: colors.secondaryTextColor,
          ),
        ),
        child: Text(
          filled ? _formatDate(value) : 'Choisir une date',
          style: textStyles.bodyTextStyle.copyWith(
            color: filled ? colors.primaryTextColor : colors.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}

/// `dd/mm/yyyy`, spelled out rather than pulled from `intl` so the app does not
/// need the French locale data loaded.
String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
