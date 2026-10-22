import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';

import '../../core/services/fumo_client.dart';
import '../../core/services/fumo_client_error.dart';
import '../../utils/json_converter.dart';
import 'upload_model.dart';

class UploadRepository {
  UploadRepository({required this._client});

  final FumoClient _client;

  Future<UploadGeocode> reverseGeocode(UploadLatLng location) async {
    final response = await _client.get(
      '/api/geocode/reverse',
      queryParameters: {'lat': location.lat, 'lng': location.lng},
      options: Options(headers: {'accept-language': _language()}),
      fallback: 'Could not look up that place.',
    );
    return UploadGeocode.fromJson(toJsonMap(response.data));
  }

  Future<List<UploadGeocode>> searchPlaces(String query) async {
    final response = await _client.get(
      '/api/geocode/search',
      queryParameters: {'q': query},
      options: Options(headers: {'accept-language': _language()}),
      fallback: 'Place search failed.',
    );
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final item in data)
        if (item is Map) UploadGeocode.fromJson(toJsonMap(item)),
    ];
  }

  Future<void> uploadBlobs(
    List<UploadBlob> blobs, {
    required void Function(String path) onUploaded,
  }) async {
    if (blobs.isEmpty) return;
    final targets = await _sign(blobs);
    var next = 0;
    Object? failure;

    Future<void> worker() async {
      while (failure == null) {
        final index = next;
        next += 1;
        if (index >= blobs.length) return;
        final blob = blobs[index];
        final target = targets[blob.path];
        if (target == null || target.size != blob.bytes.length) {
          failure = const FumoClientError('Upload target is missing.');
          return;
        }
        try {
          await _put(target, blob.bytes);
          onUploaded(blob.path);
        } catch (error) {
          failure = error;
          return;
        }
      }
    }

    final workers = blobs.length < 3 ? blobs.length : 3;
    await Future.wait(List.generate(workers, (_) => worker()));
    final error = failure;
    if (error != null) throw error;
  }

  Future<void> createPost({
    required String title,
    required String? body,
    required List<PreparedPhoto> photos,
    required DateTime? capturedAt,
    required UploadLatLng location,
    required String placeName,
    required String? countryName,
    required String? regionName,
    required String? cityName,
    required List<int> characterIds,
  }) async {
    await _client.post(
      '/api/posts',
      data: {
        'title': title,
        'body': body,
        'photos': [
          for (final photo in photos)
            {'imagePath': photo.imagePath, 'thumbPath': photo.thumbPath},
        ],
        'capturedAt': capturedAt?.toUtc().toIso8601String(),
        'exactLocation': location.toJson(),
        'publicLocation': location.toJson(),
        'privacyMode': 'exact',
        'placeName': placeName,
        'countryName': countryName,
        'regionName': regionName,
        'cityName': cityName,
        'characterIds': characterIds,
      },
      fallback: 'Could not submit the spot.',
    );
  }

  Future<void> deleteUploads(List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.post(
      '/api/storage/delete',
      data: {'paths': paths},
      fallback: 'Could not remove uploaded photos.',
    );
  }

  Future<Map<String, SignedUploadTarget>> _sign(List<UploadBlob> blobs) async {
    final response = await _client.post(
      '/api/storage/sign-upload',
      data: {
        'targets': [
          for (final blob in blobs)
            {
              'path': blob.path,
              'contentType': blob.contentType,
              'size': blob.bytes.length,
            },
        ],
      },
      fallback: 'Could not start the upload.',
    );
    final data = toJsonMap(response.data);
    final rawTargets = data['targets'];
    if (rawTargets is! List) {
      throw const FumoClientError('Signed upload targets are incomplete.');
    }
    final targets = <String, SignedUploadTarget>{};
    for (final item in rawTargets) {
      if (item is! Map) continue;
      final target = SignedUploadTarget.fromJson(toJsonMap(item));
      targets[target.path] = target;
    }
    if (targets.length != blobs.length) {
      throw const FumoClientError('Signed upload targets are incomplete.');
    }
    return targets;
  }

  Future<void> _put(SignedUploadTarget target, List<int> bytes) async {
    final client = HttpClient();
    try {
      final request = await client.putUrl(Uri.parse(target.uploadUrl));
      request.contentLength = bytes.length;
      for (final entry in target.headers.entries) {
        if (entry.key.toLowerCase() == 'content-length') continue;
        request.headers.set(entry.key, entry.value);
      }
      request.add(bytes);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw FumoClientError('Image upload failed (${response.statusCode}).');
      }
      await response.drain<void>();
    } on FumoClientError {
      rethrow;
    } catch (_) {
      throw const FumoClientError('Image upload failed.');
    } finally {
      client.close(force: true);
    }
  }

  String _language() => PlatformDispatcher.instance.locale.toLanguageTag();
}
