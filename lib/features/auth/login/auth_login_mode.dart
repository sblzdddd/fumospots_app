import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/i18n/keys.dart';

enum AuthLoginSection { login, register }

enum AuthEmailMode { password, link, register }

class AuthOAuthOption {
  const AuthOAuthOption({
    required this.provider,
    required this.loginLabelKey,
    required this.registerLabelKey,
    required this.icon,
    required this.failureMessageKey,
    this.scopes,
  });

  final String provider;
  final String loginLabelKey;
  final String registerLabelKey;
  final FaIconData icon;
  final String failureMessageKey;
  final String? scopes;
}

const authOAuthOptions = [
  AuthOAuthOption(
    provider: 'github',
    loginLabelKey: S.githubLogin,
    registerLabelKey: S.githubRegister,
    icon: FontAwesomeIcons.github,
    failureMessageKey: S.githubFailed,
  ),
  AuthOAuthOption(
    provider: 'google',
    loginLabelKey: S.googleLogin,
    registerLabelKey: S.googleRegister,
    icon: FontAwesomeIcons.google,
    failureMessageKey: S.googleFailed,
  ),
  AuthOAuthOption(
    provider: 'azure',
    loginLabelKey: S.microsoftLogin,
    registerLabelKey: S.microsoftRegister,
    icon: FontAwesomeIcons.microsoft,
    failureMessageKey: S.microsoftFailed,
    scopes: 'email',
  ),
];

AuthEmailMode? authEmailMode(AuthLoginSection section, int? methodIndex) {
  if (methodIndex == null) {
    return null;
  }
  if (methodIndex == 0) {
    return AuthEmailMode.link;
  }
  if (section == AuthLoginSection.register) {
    return AuthEmailMode.register;
  }
  return AuthEmailMode.password;
}
