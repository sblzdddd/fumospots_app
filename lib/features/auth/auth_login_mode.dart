import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum AuthLoginSection { login, register }

enum AuthEmailMode { password, link, register }

class AuthOAuthOption {
  const AuthOAuthOption({
    required this.provider,
    required this.loginLabel,
    required this.registerLabel,
    required this.icon,
    required this.failureMessage,
    this.scopes,
  });

  final String provider;
  final String loginLabel;
  final String registerLabel;
  final FaIconData icon;
  final String failureMessage;
  final String? scopes;
}

const authOAuthOptions = [
  AuthOAuthOption(
    provider: 'github',
    loginLabel: 'GitHub login',
    registerLabel: 'Register with GitHub',
    icon: FontAwesomeIcons.github,
    failureMessage: 'GitHub login failed.',
  ),
  AuthOAuthOption(
    provider: 'google',
    loginLabel: 'Google login',
    registerLabel: 'Register with Google',
    icon: FontAwesomeIcons.google,
    failureMessage: 'Google login failed.',
  ),
  AuthOAuthOption(
    provider: 'azure',
    loginLabel: 'Microsoft login',
    registerLabel: 'Register with Microsoft',
    icon: FontAwesomeIcons.microsoft,
    failureMessage: 'Microsoft login failed.',
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
