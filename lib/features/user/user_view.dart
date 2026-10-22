import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/fumo_client_error.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_login_methods.dart';
import '../auth/auth_login_view.dart';
import '../settings/settings_view.dart';

class UserView extends StatelessWidget {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = GetIt.instance<AuthController>();
    final barHeight = BottomBarScope.maybeOf(context)?.barHeight;
    final topInset = MediaQuery.paddingOf(context).top;

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        Widget body(double bottomPadding) {
          final signedIn = auth.isSignedIn;
          final username = auth.user?.profile.username;
          final email = auth.user?.email;
          final hasUsername = username != null && username.isNotEmpty;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, bottomPadding),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: FaIcon(
                    signedIn
                        ? FontAwesomeIcons.solidUser
                        : FontAwesomeIcons.user,
                    size: 18,
                  ),
                ),
                title: Text(
                  !signedIn
                      ? 'Not signed in'
                      : hasUsername
                      ? '@$username'
                      : 'Signed in',
                ),
                subtitle: signedIn && email != null && email.isNotEmpty
                    ? Text(email)
                    : null,
              ),
              const SizedBox(height: 16),
              FullWidthToggleGroup(
                size: M3EButtonSize.md,
                trailingExtent: FullWidthToggleGroup.iconExtent,
                onSelectedIndexChanged: (index) {
                  if (index == 0) {
                    if (!auth.ready || auth.busy) {
                      return;
                    }
                    if (signedIn) {
                      _signOut(context, auth);
                    } else {
                      _openLogin(context);
                    }
                  } else if (index == 1) {
                    _openSettings(context);
                  }
                },
                actions: (first, second) => [
                  M3EToggleButtonGroupAction(
                    width: first,
                    enabled: auth.ready && !auth.busy,
                    icon: FaIcon(
                      signedIn
                          ? FontAwesomeIcons.rightFromBracket
                          : FontAwesomeIcons.rightToBracket,
                      size: 20,
                    ),
                    label: Text(signedIn ? 'Sign out' : 'Sign in'),
                  ),
                  M3EToggleButtonGroupAction(
                    width: second,
                    icon: const FaIcon(FontAwesomeIcons.gear, size: 20),
                    tooltip: 'Settings',
                    semanticLabel: 'Settings',
                  ),
                ],
              ),
              if (auth.ready && signedIn && !auth.hasUsername) ...[
                const SizedBox(height: 12),
                M3EButton.icon(
                  onPressed: () => _openLogin(context),
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.md,
                  shape: M3EButtonShape.round,
                  decoration: authWideButtonDecoration,
                  icon: const FaIcon(FontAwesomeIcons.userPen, size: 16),
                  label: const Text('Set author ID'),
                ),
              ],
            ],
          );
        }

        if (barHeight == null) {
          return body(MediaQuery.paddingOf(context).bottom + 16);
        }
        return ValueListenableBuilder<double>(
          valueListenable: barHeight,
          builder: (context, value, _) => body(value + 16),
        );
      },
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AuthLoginView()));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
  }

  Future<void> _signOut(BuildContext context, AuthController auth) async {
    try {
      await auth.signOut();
    } on FumoClientError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
