import 'dart:async';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'location/upload_location_section.dart';
import 'photo/upload_photo_section.dart';
import 'upload_character_field.dart';
import 'upload_controller.dart';
import 'upload_detail_fields.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final UploadController _controller = GetIt.instance<UploadController>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _place = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  final TextEditingController _captured = TextEditingController();
  final FocusNode _latitudeFocus = FocusNode();
  final FocusNode _longitudeFocus = FocusNode();

  static final _wideButton = M3EButtonDecoration.styleFrom(
    minimumSize: const Size(double.infinity, 48),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
    _latitudeFocus.addListener(_onCoordinateFocus);
    _longitudeFocus.addListener(_onCoordinateFocus);
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _latitudeFocus.removeListener(_onCoordinateFocus);
    _longitudeFocus.removeListener(_onCoordinateFocus);
    _title.dispose();
    _body.dispose();
    _place.dispose();
    _search.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _captured.dispose();
    _latitudeFocus.dispose();
    _longitudeFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    _setText(_place, _controller.placeName);
    _setText(_search, _controller.searchQuery);
    _setText(_latitude, _controller.latitudeText);
    _setText(_longitude, _controller.longitudeText);
    _setText(_captured, formatCapturedAt(_controller.capturedAt));
    if (mounted) setState(() {});
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _onCoordinateFocus() {
    if (_latitudeFocus.hasFocus || _longitudeFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_latitudeFocus.hasFocus || _longitudeFocus.hasFocus) return;
      unawaited(_controller.applyCoordinates());
    });
  }

  Future<void> _pickCapturedAt() async {
    final now = DateTime.now();
    final initial = _controller.capturedAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    _controller.setCapturedAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _submit() async {
    final submitted = await _controller.submit();
    if (!submitted || !mounted) return;
    Navigator.of(context).pop('Spot submitted.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final uploading = _controller.uploading;
    final progress = _controller.uploadProgress;

    return PopScope(
      canPop: !uploading,
      child: Scaffold(
        appBar: AppBar(title: const Text('New spot')),
        body: Column(
          children: [
            if (uploading)
              M3ELinearProgressIndicator(value: progress, minHeight: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  UploadPhotoSection(controller: _controller),
                  const SizedBox(height: 20),
                  UploadDetailFields(
                    enabled: !uploading,
                    title: _title,
                    body: _body,
                    captured: _captured,
                    hasCaptured: _controller.capturedAt != null,
                    onTitle: _controller.setTitle,
                    onBody: _controller.setBody,
                    onPickCaptured: _pickCapturedAt,
                    onClearCaptured: () => _controller.setCapturedAt(null),
                  ),
                  const SizedBox(height: 16),
                  UploadCharacterField(
                    enabled: !uploading,
                    onChanged: _controller.setCharacterIds,
                  ),
                  const SizedBox(height: 20),
                  UploadLocationSection(
                    controller: _controller,
                    search: _search,
                    place: _place,
                    latitude: _latitude,
                    longitude: _longitude,
                    latitudeFocus: _latitudeFocus,
                    longitudeFocus: _longitudeFocus,
                  ),
                  if (_controller.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _controller.error!,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: M3EButton.icon(
                  onPressed: _controller.canSubmit ? _submit : null,
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.md,
                  shape: M3EButtonShape.round,
                  decoration: _wideButton,
                  icon: FaIcon(
                    uploading
                        ? FontAwesomeIcons.spinner
                        : FontAwesomeIcons.paperPlane,
                    size: 16,
                  ),
                  label: Text(
                    uploading
                        ? '${_controller.progressLabel}${progress == null ? '' : ' ${(progress * 100).round()}%'}'
                        : 'Submit spot',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
