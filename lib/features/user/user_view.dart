import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n/i18n.dart';
import '../../core/services/fumo_client_error.dart';
import '../auth/auth_controller.dart';
import '../auth/login/auth_login_methods.dart';
import '../auth/login/auth_login_view.dart';
import '../settings/settings_view.dart';
import 'user_controller.dart';
import 'user_model.dart';
import 'user_posts_actions.dart';
import 'user_posts_section.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final AuthController _auth = GetIt.instance<AuthController>();
  final UserController _user = GetIt.instance<UserController>();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPosts());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _syncPosts();
    if (mounted) setState(() {});
  }

  void _syncPosts() {
    if (_auth.isSignedIn && _auth.hasUsername) {
      _user.loadForSignedInUser();
    } else {
      _user.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final barHeight = BottomBarScope.maybeOf(context)?.barHeight;
    final topInset = MediaQuery.paddingOf(context).top;

    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final signedIn = _auth.isSignedIn;
        final username = _auth.user?.profile.username;
        final email = _auth.user?.email;
        final hasUsername = username != null && username.isNotEmpty;
        final showPosts = signedIn && hasUsername;

        Widget header(double bottomPadWhenNoPosts) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              topInset + 12,
              16,
              showPosts ? 8 : bottomPadWhenNoPosts,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        ? context.t(S.notSignedIn)
                        : hasUsername
                        ? '@$username'
                        : context.t(S.signedIn),
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
                      if (!_auth.ready || _auth.busy) {
                        return;
                      }
                      if (signedIn) {
                        _signOut(context);
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
                      enabled: _auth.ready && !_auth.busy,
                      icon: FaIcon(
                        signedIn
                            ? FontAwesomeIcons.rightFromBracket
                            : FontAwesomeIcons.rightToBracket,
                        size: 20,
                      ),
                      label: Text(
                        context.t(signedIn ? S.signOut : S.signIn),
                      ),
                    ),
                    M3EToggleButtonGroupAction(
                      width: second,
                      icon: const FaIcon(FontAwesomeIcons.gear, size: 20),
                      tooltip: context.t(S.settings),
                      semanticLabel: context.t(S.settings),
                    ),
                  ],
                ),
                if (_auth.ready && signedIn && !hasUsername) ...[
                  const SizedBox(height: 12),
                  M3EButton.icon(
                    onPressed: () => _openLogin(context),
                    style: M3EButtonStyle.filled,
                    size: M3EButtonSize.md,
                    shape: M3EButtonShape.round,
                    decoration: authWideButtonDecoration,
                    icon: const FaIcon(FontAwesomeIcons.userPen, size: 16),
                    label: Text(context.t(S.setAuthorId)),
                  ),
                ],
              ],
            ),
          );
        }

        Widget body(double bottomPadding) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header(bottomPadding),
              if (showPosts)
                Expanded(
                  child: UserPostsSection(
                    onOpenPost: _onOpenPost,
                    onEditPost: _onEditPost,
                  ),
                ),
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

  Future<void> _onOpenPost(UserPostSummary post) =>
      openUserPost(context, post);

  Future<void> _onEditPost(UserPostSummary post) async {
    final message = await editUserPost(context, post);
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t(message))));
      await _user.refresh();
    }
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AuthLoginView()));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      _user.clear();
    } on FumoClientError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t(error.message))),
        );
      }
    }
  }
}
