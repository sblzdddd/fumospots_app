import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/config/fumospots_config.dart';
import 'auth_exception.dart';

const authMinPasswordLength = 8;

final authUsernamePattern = RegExp(r'^[a-z0-9_-]{3,24}$');

class AuthPkce {
  AuthPkce({required this.verifier, required this.challenge});

  final String verifier;
  final String challenge;

  factory AuthPkce.generate() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final verifier = base64UrlEncode(bytes).replaceAll('=', '');
    final digest = sha256.convert(utf8.encode(verifier));
    final challenge = base64UrlEncode(digest.bytes).replaceAll('=', '');
    return AuthPkce(verifier: verifier, challenge: challenge);
  }
}

class AuthLinks {
  AuthLinks({required this.siteUrl, required this.supabaseUrl});

  factory AuthLinks.fromConfig(FumospotsConfig config) {
    return AuthLinks(siteUrl: config.siteUrl, supabaseUrl: config.supabaseUrl);
  }

  final String siteUrl;
  final String supabaseUrl;

  Uri get loginRedirect {
    final site = Uri.parse(siteUrl.trim());
    if (site.scheme.isEmpty || site.host.isEmpty) {
      throw const AuthException('Sign-in redirect is not configured.');
    }
    return Uri(
      scheme: site.scheme,
      host: site.host,
      port: site.hasPort ? site.port : null,
      path: '/',
      queryParameters: const {'panel': 'login'},
    );
  }

  Uri authorize({
    required String provider,
    required String codeChallenge,
    String? scopes,
  }) {
    final root = supabaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final base = Uri.parse(root);
    if (base.scheme.isEmpty || base.host.isEmpty) {
      throw const AuthException('Sign-in is not configured.');
    }
    return base.replace(
      path: '/auth/v1/authorize',
      queryParameters: {
        'provider': provider,
        'redirect_to': loginRedirect.toString(),
        'code_challenge': codeChallenge,
        'code_challenge_method': 's256',
        if (scopes != null && scopes.isNotEmpty) 'scopes': scopes,
      },
    );
  }
}

class AuthCallback {
  const AuthCallback({
    this.code,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
    this.errorDescription,
  });

  final String? code;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final int? expiresAt;
  final String? errorDescription;

  bool get hasCode => code != null && code!.isNotEmpty;

  bool get hasSessionTokens =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;

  bool get hasError => errorDescription != null && errorDescription!.isNotEmpty;

  static AuthCallback? tryParse(String raw) {
    final hashIndex = raw.indexOf('#');
    final beforeHash = hashIndex == -1 ? raw : raw.substring(0, hashIndex);
    final queryIndex = beforeHash.indexOf('?');
    final rawQuery = queryIndex == -1
        ? ''
        : beforeHash.substring(queryIndex + 1);
    final rawFragment = hashIndex == -1 ? '' : raw.substring(hashIndex + 1);
    final params = {..._split(rawQuery), ..._split(rawFragment)};
    final code = _nonEmpty(params['code']);
    final accessToken = _nonEmpty(params['access_token']);
    final refreshToken = _nonEmpty(params['refresh_token']);
    final error = _nonEmpty(params['error_description']) ?? _nonEmpty(params['error']);
    if (code == null && accessToken == null && refreshToken == null && error == null) {
      return null;
    }
    return AuthCallback(
      code: code,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: int.tryParse(params['expires_in'] ?? ''),
      expiresAt: int.tryParse(params['expires_at'] ?? ''),
      errorDescription: error?.replaceAll('+', ' '),
    );
  }

  static Map<String, String> _split(String query) {
    if (query.isEmpty) {
      return const {};
    }
    final params = <String, String>{};
    for (final part in query.split('&')) {
      if (part.isEmpty) {
        continue;
      }
      final index = part.indexOf('=');
      if (index == -1) {
        params[_decode(part)] = '';
        continue;
      }
      params[_decode(part.substring(0, index))] = _decode(
        part.substring(index + 1),
      );
    }
    return params;
  }

  static String _decode(String value) {
    try {
      return Uri.decodeQueryComponent(value);
    } on ArgumentError {
      return value;
    }
  }

  static String? _nonEmpty(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

bool sameAuthOrigin(Uri landed, Uri callback) {
  return landed.scheme == callback.scheme &&
      landed.host.toLowerCase() == callback.host.toLowerCase() &&
      landed.port == callback.port;
}

class AuthBrowserResult {
  const AuthBrowserResult({required this.succeeded, this.message});

  final bool succeeded;
  final String? message;
}
