import 'package:get_it/get_it.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/auth_session_store.dart';
import '../../features/post/post_detail_controller.dart';
import '../../features/post/post_feed_controller.dart';
import '../../features/post/post_repository.dart';
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
}
