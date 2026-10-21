import 'package:flutter_dotenv/flutter_dotenv.dart';

class FumospotsConfig {
  const FumospotsConfig({
    required this.siteUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory FumospotsConfig.fromDotEnv() {
    return FumospotsConfig(
      siteUrl: _require('SITE_URL'),
      supabaseUrl: _require('SUPABASE_URL'),
      supabaseAnonKey: _require('SUPABASE_ANON_KEY'),
    );
  }

  final String siteUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  static String _require(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in .env');
    }
    return value;
  }
}
