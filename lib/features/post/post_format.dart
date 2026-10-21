import 'dart:ui';

import 'post_model.dart';

String deviceLocale() {
  return PlatformDispatcher.instance.locale.toLanguageTag();
}

String characterName(PostCharacter character, String locale) {
  final normalized = locale.toLowerCase();
  if (normalized.startsWith('zh') && character.nameZh != null) {
    return character.nameZh!;
  }
  if (normalized.startsWith('ja') && character.nameJa != null) {
    return character.nameJa!;
  }
  return character.nameEn;
}

String formatDateTime(String? value, String locale) {
  if (value == null || value.isEmpty) {
    return 'Not provided';
  }

  final date = DateTime.tryParse(value);
  if (date == null) {
    return 'Not provided';
  }

  return date.toLocal().toString().substring(0, 16);
}

String formatLatLng(PostLatLng? value) {
  if (value == null) {
    return 'Not set';
  }
  return '${value.lat.toStringAsFixed(5)}, ${value.lng.toStringAsFixed(5)}';
}

List<PostPhoto> displayPhotos(PostDetail post) {
  final photos = post.photos
      .where((photo) => photo.imageUrl != null || photo.thumbUrl != null)
      .toList();
  if (photos.isNotEmpty) {
    return photos;
  }
  if (post.imageUrl != null || post.thumbUrl != null) {
    return [PostPhoto(imageUrl: post.imageUrl, thumbUrl: post.thumbUrl)];
  }
  return const [];
}
