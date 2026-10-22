import 'package:material_ui/material_ui.dart';

import 'upload_model.dart';

class UploadDetailFields extends StatelessWidget {
  const UploadDetailFields({
    super.key,
    required this.enabled,
    required this.title,
    required this.body,
    required this.captured,
    required this.hasCaptured,
    required this.onTitle,
    required this.onBody,
    required this.onPickCaptured,
    required this.onClearCaptured,
  });

  final bool enabled;
  final TextEditingController title;
  final TextEditingController body;
  final TextEditingController captured;
  final bool hasCaptured;
  final ValueChanged<String> onTitle;
  final ValueChanged<String> onBody;
  final VoidCallback onPickCaptured;
  final VoidCallback onClearCaptured;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: title,
          enabled: enabled,
          maxLength: maxTitleLength,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'What is this spot?',
            border: OutlineInputBorder(),
          ),
          onChanged: onTitle,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: body,
          enabled: enabled,
          maxLength: maxBodyLength,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Notes',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          onChanged: onBody,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: captured,
          readOnly: true,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: 'Captured',
            border: const OutlineInputBorder(),
            suffixIcon: hasCaptured
                ? IconButton(
                    tooltip: 'Clear date',
                    onPressed: enabled ? onClearCaptured : null,
                    icon: const Icon(Icons.close),
                  )
                : const Icon(Icons.calendar_today_outlined),
          ),
          onTap: enabled ? onPickCaptured : null,
        ),
      ],
    );
  }
}

String formatCapturedAt(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
