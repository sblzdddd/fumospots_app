class FumospotsConfig {
  const FumospotsConfig({
    required this.siteUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  static const FumospotsConfig fromEnvironment = FumospotsConfig(
    siteUrl: String.fromEnvironment('SITE_URL'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String siteUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
}
