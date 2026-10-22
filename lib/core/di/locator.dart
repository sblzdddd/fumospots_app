import 'package:get_it/get_it.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/auth_session_store.dart';
import '../../features/character/character_catalog_controller.dart';
import '../../features/character/character_repository.dart';
import '../../features/character/filter/character_filter_controller.dart';
import '../../features/map/map_points_controller.dart';
import '../../features/map/map_repository.dart';
import '../../features/map/preview/map_preview_controller.dart';
import '../../features/post/detail/post_detail_controller.dart';
import '../../features/post/feed/post_feed_controller.dart';
import '../../features/post/post_repository.dart';
import '../../features/upload/upload_controller.dart';
import '../../features/upload/upload_repository.dart';
import '../../features/settings/theme_controller.dart';
import '../../features/settings/visual_settings_controller.dart';
import '../config/fumospots_config.dart';
import '../services/fumo_client.dart';
import '../services/fumo_store.dart';
import '../services/image_cache_service.dart';
import '../services/interceptors/fumo_auth_interceptor.dart';

final getIt = GetIt.instance;

void setupDI() {
  // Basic Services

  if (!getIt.isRegistered<FumospotsConfig>()) {
    getIt.registerSingleton<FumospotsConfig>(FumospotsConfig.fromDotEnv());
  }

  if (!getIt.isRegistered<FumoStore>()) {
    getIt.registerSingleton<FumoStore>(FumoStore());
  }

  if (!getIt.isRegistered<FumoClient>()) {
    getIt.registerSingleton<FumoClient>(FumoClient());
  }

  if (!getIt.isRegistered<ImageCacheService>()) {
    getIt.registerLazySingleton<ImageCacheService>(ImageCacheService.new);
  }

  if (!getIt.isRegistered<ThemeController>()) {
    getIt.registerLazySingleton<ThemeController>(ThemeController.new);
  }

  if (!getIt.isRegistered<VisualSettingsController>()) {
    getIt.registerLazySingleton<VisualSettingsController>(
      VisualSettingsController.new,
    );
  }

  // Auth

  if (!getIt.isRegistered<AuthSessionStore>()) {
    getIt.registerSingleton<AuthSessionStore>(
      AuthSessionStore(store: getIt<FumoStore>()),
    );
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerSingleton<AuthRepository>(
      AuthRepository(
        client: getIt<FumoClient>(),
        sessions: getIt<AuthSessionStore>(),
        config: getIt<FumospotsConfig>(),
      ),
    );
  }

  if (!getIt.isRegistered<AuthController>()) {
    getIt.registerSingleton<AuthController>(AuthController());
  }

  // Auth Interceptor Post Initialize

  if (!getIt.isRegistered<FumoAuthInterceptor>()) {
    final interceptor = FumoAuthInterceptor();
    getIt.registerSingleton<FumoAuthInterceptor>(interceptor);
    getIt<FumoClient>().postInitialize(interceptor);
  }

  // Characters

  if (!getIt.isRegistered<CharacterRepository>()) {
    getIt.registerLazySingleton<CharacterRepository>(
      () => CharacterRepository(client: getIt<FumoClient>()),
    );
  }

  if (!getIt.isRegistered<CharacterCatalogController>()) {
    getIt.registerLazySingleton<CharacterCatalogController>(
      CharacterCatalogController.new,
    );
  }

  if (!getIt.isRegistered<CharacterFilterController>()) {
    getIt.registerLazySingleton<CharacterFilterController>(
      CharacterFilterController.new,
    );
  }

  // Posts

  if (!getIt.isRegistered<PostRepository>()) {
    getIt.registerLazySingleton<PostRepository>(
      () => PostRepository(client: getIt<FumoClient>()),
    );
  }

  if (!getIt.isRegistered<PostFeedController>()) {
    getIt.registerLazySingleton<PostFeedController>(PostFeedController.new);
  }

  if (!getIt.isRegistered<PostDetailController>()) {
    getIt.registerFactory<PostDetailController>(PostDetailController.new);
  }

  if (!getIt.isRegistered<UploadRepository>()) {
    getIt.registerLazySingleton<UploadRepository>(
      () => UploadRepository(client: getIt<FumoClient>()),
    );
  }

  if (!getIt.isRegistered<UploadController>()) {
    getIt.registerFactory<UploadController>(UploadController.new);
  }

  // Map

  if (!getIt.isRegistered<MapRepository>()) {
    getIt.registerLazySingleton<MapRepository>(
      () => MapRepository(client: getIt<FumoClient>()),
    );
  }

  if (!getIt.isRegistered<MapPointsController>()) {
    getIt.registerLazySingleton<MapPointsController>(MapPointsController.new);
  }

  if (!getIt.isRegistered<MapPreviewController>()) {
    getIt.registerLazySingleton<MapPreviewController>(MapPreviewController.new);
  }
}
