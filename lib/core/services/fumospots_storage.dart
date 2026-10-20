import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synchronized/synchronized.dart';

// OpenCMS Inheritage
class FumospotsStorage {
  final _lock = Lock();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(enforceBiometrics: false),
    iOptions: IOSOptions(),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(),
  );

  Future<String?> read({required String key}) async {
    return _lock.synchronized(() => _storage.read(key: key));
  }

  Future<Map<String, String>> readAll() async {
    return _lock.synchronized(() => _storage.readAll());
  }

  Future<void> write({required String key, required String value}) async {
    await _lock.synchronized(() => _storage.write(key: key, value: value));
  }

  Future<void> delete({required String key}) async {
    await _lock.synchronized(() => _storage.delete(key: key));
  }

  Future<void> deleteAll() async {
    await _lock.synchronized(() => _storage.deleteAll());
  }
}