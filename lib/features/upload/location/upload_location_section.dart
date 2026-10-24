import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';
import '../upload_controller.dart';
import '../upload_section.dart';

class UploadLocationSection extends StatelessWidget {
  const UploadLocationSection({
    super.key,
    required this.controller,
    required this.search,
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.latitudeFocus,
    required this.longitudeFocus,
  });

  final UploadController controller;
  final TextEditingController search;
  final TextEditingController place;
  final TextEditingController latitude;
  final TextEditingController longitude;
  final FocusNode latitudeFocus;
  final FocusNode longitudeFocus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final uploading = controller.uploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UploadSectionLabel(context.t(S.location), required: true),
        const SizedBox(height: 8),
        UploadActionPair(
          first: UploadAction(
            label: context.t(S.device),
            icon: FontAwesomeIcons.locationDot,
            onPressed: uploading || controller.locating
                ? null
                : controller.fillFromDevice,
          ),
          second: UploadAction(
            label: context.t(S.photoExif),
            icon: FontAwesomeIcons.image,
            onPressed:
                uploading ||
                    controller.photos.isEmpty ||
                    controller.detectingExif
                ? null
                : () => controller.fillFromPhoto(overwrite: true),
          ),
        ),
        if (controller.locationBusy) ...[
          const SizedBox(height: 8),
          Text(
            _status(context, controller),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        _PlaceSearch(controller: controller, search: search),
        if (controller.searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SearchResults(controller: controller),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: place,
          enabled: !uploading,
          decoration: InputDecoration(
            labelText: context.t(S.placeName),
            border: const OutlineInputBorder(),
          ),
          onChanged: controller.setPlaceName,
        ),
        const SizedBox(height: 12),
        _PlaceFacts(
          country: controller.countryName,
          region: controller.regionName,
          city: controller.cityName,
          loading: controller.reverseLookup,
        ),
        const SizedBox(height: 12),
        _Coordinates(
          enabled: !uploading,
          latitude: latitude,
          longitude: longitude,
          latitudeFocus: latitudeFocus,
          longitudeFocus: longitudeFocus,
          onLatitude: controller.setLatitudeText,
          onLongitude: controller.setLongitudeText,
          onSubmit: controller.applyCoordinates,
        ),
        if (controller.coordinateError != null) ...[
          const SizedBox(height: 8),
          Text(
            context.t(controller.coordinateError!),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  String _status(BuildContext context, UploadController controller) {
    if (controller.locating) return context.t(S.readingDeviceLocation);
    if (controller.reverseLookup) return context.t(S.lookingUpPlace);
    return context.t(S.readingPhotoLocation);
  }
}

class _PlaceSearch extends StatelessWidget {
  const _PlaceSearch({required this.controller, required this.search});

  final UploadController controller;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final busy = controller.uploading || controller.searching;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: search,
            enabled: !controller.uploading,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: context.t(S.searchPlace),
              hintText: context.t(S.searchPlaceHint),
              border: const OutlineInputBorder(),
            ),
            onChanged: controller.setSearchQuery,
            onSubmitted: (_) => controller.searchPlaces(),
          ),
        ),
        const SizedBox(width: 8),
        M3EButton(
          onPressed: busy || search.text.trim().length < 2
              ? null
              : controller.searchPlaces,
          style: M3EButtonStyle.tonal,
          shape: M3EButtonShape.round,
          size: M3EButtonSize.md,
          tooltip: context.t(S.search),
          semanticLabel: context.t(S.searchPlaces),
          child: FaIcon(
            controller.searching
                ? FontAwesomeIcons.spinner
                : FontAwesomeIcons.magnifyingGlass,
            size: 16,
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.controller});

  final UploadController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return M3ESegmentedColumn(
      onTap: (index) => controller.selectPlace(controller.searchResults[index]),
      children: [
        for (final result in controller.searchResults)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.placeName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  result.displayName,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlaceFacts extends StatelessWidget {
  const _PlaceFacts({
    required this.country,
    required this.region,
    required this.city,
    required this.loading,
  });

  final String? country;
  final String? region;
  final String? city;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Fact(
            label: context.t(S.country),
            value: country,
            loading: loading,
          ),
        ),
        Expanded(
          child: _Fact(
            label: context.t(S.region),
            value: region,
            loading: loading,
          ),
        ),
        Expanded(
          child: _Fact(
            label: context.t(S.city),
            value: city,
            loading: loading,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.loading,
  });

  final String label;
  final String? value;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          loading ? '…' : (value ?? '—'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _Coordinates extends StatelessWidget {
  const _Coordinates({
    required this.enabled,
    required this.latitude,
    required this.longitude,
    required this.latitudeFocus,
    required this.longitudeFocus,
    required this.onLatitude,
    required this.onLongitude,
    required this.onSubmit,
  });

  final bool enabled;
  final TextEditingController latitude;
  final TextEditingController longitude;
  final FocusNode latitudeFocus;
  final FocusNode longitudeFocus;
  final ValueChanged<String> onLatitude;
  final ValueChanged<String> onLongitude;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const kind = TextInputType.numberWithOptions(decimal: true, signed: true);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: latitude,
            focusNode: latitudeFocus,
            enabled: enabled,
            keyboardType: kind,
            decoration: InputDecoration(
              labelText: context.t(S.latitude),
              border: const OutlineInputBorder(),
            ),
            onChanged: onLatitude,
            onSubmitted: (_) => longitudeFocus.requestFocus(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: longitude,
            focusNode: longitudeFocus,
            enabled: enabled,
            keyboardType: kind,
            decoration: InputDecoration(
              labelText: context.t(S.longitude),
              border: const OutlineInputBorder(),
            ),
            onChanged: onLongitude,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
      ],
    );
  }
}
