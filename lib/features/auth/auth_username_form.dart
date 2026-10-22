import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_login_methods.dart';
import 'auth_login_notice.dart';

class AuthUsernameForm extends StatelessWidget {
  const AuthUsernameForm({
    super.key,
    required this.email,
    required this.username,
    required this.busy,
    required this.error,
    required this.onSave,
    required this.onSignOut,
    required this.onChanged,
  });

  final String? email;
  final TextEditingController username;
  final bool busy;
  final String? error;
  final VoidCallback onSave;
  final VoidCallback onSignOut;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (email != null && email!.isNotEmpty) ...[
          Text(email!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: username,
          enabled: !busy,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Author ID',
            hintText: 'reimu_tabi',
            helperText: 'Examples: reimu_tabi, alice_fumo, world_trip_01.',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSave(),
          onChanged: (_) => onChanged(),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          AuthLoginNotice(message: error!, isError: true),
        ],
        const SizedBox(height: 16),
        M3EButton(
          onPressed: busy ? null : onSave,
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.md,
          shape: M3EButtonShape.round,
          decoration: authWideButtonDecoration,
          child: Text(busy ? 'Saving…' : 'Save author ID'),
        ),
        const SizedBox(height: 8),
        M3EButton(
          onPressed: busy ? null : onSignOut,
          style: M3EButtonStyle.text,
          size: M3EButtonSize.md,
          shape: M3EButtonShape.round,
          decoration: authWideButtonDecoration,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
