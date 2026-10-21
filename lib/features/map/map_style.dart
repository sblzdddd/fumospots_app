import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/fumospots_config.dart';

/// Keep in step with fumospots/shared/mapStyle.ts.
const mapStyleRevision = '20260802-12';

const mapDefaultCenterLon = 116.397389;
const mapDefaultCenterLat = 39.908722;
const mapDefaultZoom = 1.55;

/// Switch from circle dots to image preview pins at this zoom.
const mapPreviewMinZoom = 10.0;
const mapPreviewThumbSize = 48.0;
/// Corner radius as a fraction of [mapPreviewThumbSize] (1 = pill/circle).
const mapPreviewCornerFraction = 0.22;
const mapPreviewMaxVisible = 100;

/// Official marker palette from fumospots/app WorldMap.vue.
class MapPalette {
  const MapPalette({
    required this.primary,
    required this.contrast,
    required this.halo,
  });

  factory MapPalette.of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  static const light = MapPalette(
    primary: Color(0xFF248E55),
    contrast: Color(0xFFF7F3EC),
    halo: Color(0x3316925F),
  );

  static const dark = MapPalette(
    primary: Color(0xFF31A567),
    contrast: Color(0xFF0F120E),
    halo: Color(0x3D58C78F),
  );

  final Color primary;
  final Color contrast;
  final Color halo;
}

String mapStyleLanguage([String? locale]) {
  final normalized = (locale ?? PlatformDispatcher.instance.locale.toLanguageTag())
      .trim();
  if (normalized.isEmpty) {
    return 'zh-Hans';
  }
  if (normalized == 'zh-CN' || normalized.startsWith('zh-Hans')) {
    return 'zh-Hans';
  }
  if (normalized == 'zh-TW' || normalized.startsWith('zh-Hant')) {
    return 'zh-Hant';
  }
  if (normalized.startsWith('ja')) {
    return 'ja';
  }
  return 'en';
}

String hostedMapStyleUrl({required bool dark}) {
  final site = GetIt.instance<FumospotsConfig>().siteUrl.replaceAll(
    RegExp(r'/$'),
    '',
  );
  final theme = dark ? 'dark' : 'light';
  final lang = Uri.encodeQueryComponent(mapStyleLanguage());
  return '$site/api/map/style/$theme?lang=$lang&v=$mapStyleRevision';
}
