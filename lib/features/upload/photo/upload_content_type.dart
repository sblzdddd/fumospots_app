String? contentTypeFor(String path, String? mimeType) {
  switch (extensionOf(path)) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.avif':
      return 'image/avif';
    case '.heic':
    case '.heif':
      return 'image/heic';
  }
  switch (mimeType) {
    case 'image/jpeg':
    case 'image/png':
    case 'image/webp':
    case 'image/gif':
    case 'image/avif':
    case 'image/heic':
    case 'image/heif':
      return mimeType;
  }
  return null;
}

String extForContentType(String type) {
  switch (type) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/gif':
      return 'gif';
    case 'image/avif':
      return 'avif';
    default:
      return 'webp';
  }
}

String extensionOf(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '';
  return name.substring(dot).toLowerCase();
}
