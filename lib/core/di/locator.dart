import 'package:get_it/get_it.dart';
import '../services/fumospots_storage.dart';

final getIt = GetIt.instance;

void setupDI() {
  getIt.registerSingleton<FumospotsStorage>(FumospotsStorage());
}
