import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_login_methods.dart';
import 'auth_login_mode.dart';
import 'auth_login_notice.dart';

class AuthLoginFields extends StatelessWidget {
  const AuthLoginFields({
    super.key,
    required this.mode,
    required this.busy,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.callback,
    required this.formKey,
    required this.notice,
    required this.error,
    required this.awaitingEmail,
    required this.canSubmit,
    required this.submitLabel,
    required this.onSubmit,
    required this.onContinue,
    required this.onChanged,
  });

  final AuthEmailMode? mode;
  final bool busy;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final TextEditingController callback;
  final GlobalKey formKey;
  final String? notice;
  final String? error;
  final bool awaitingEmail;
  final bool canSubmit;
  final String submitLabel;
  final VoidCallback onSubmit;
  final VoidCallback onContinue;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final link = mode == AuthEmailMode.link;
    final register = mode == AuthEmailMode.register;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mode != null) ...[
          const SizedBox(height: 16),
          Column(
            key: formKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: link
                    ? TextInputAction.done
                    : TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onChanged(),
                onSubmitted: (_) {
                  if (link) {
                    onSubmit();
                  }
                },
              ),
              if (!link) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 8 characters',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (!register) {
                      onSubmit();
                    }
                  },
                ),
              ],
              if (register) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassword,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    hintText: 'Enter the password again',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ],
            ],
          ),
        ],
        if (notice != null) ...[
          const SizedBox(height: 16),
          AuthLoginNotice(message: notice!, isError: false),
        ],
        if (awaitingEmail) ...[
          const SizedBox(height: 12),
          TextField(
            controller: callback,
            enabled: !busy,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Email link or code',
              hintText: 'Paste the link, or enter the code',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          M3EButton(
            onPressed: busy ? null : onContinue,
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            decoration: authWideButtonDecoration,
            child: Text(busy ? 'Processing...' : 'Continue'),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          AuthLoginNotice(message: error!, isError: true),
        ],
        if (mode != null && !awaitingEmail) ...[
          const SizedBox(height: 16),
          M3EButton.icon(
            onPressed: canSubmit ? onSubmit : null,
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            decoration: authWideButtonDecoration,
            icon: FaIcon(_submitIcon(mode), size: 16),
            label: Text(submitLabel),
          ),
        ],
      ],
    );
  }

  FaIconData _submitIcon(AuthEmailMode? mode) {
    return switch (mode) {
      AuthEmailMode.link => FontAwesomeIcons.envelope,
      AuthEmailMode.register => FontAwesomeIcons.userPlus,
      AuthEmailMode.password || null => FontAwesomeIcons.rightToBracket,
    };
  }
}
