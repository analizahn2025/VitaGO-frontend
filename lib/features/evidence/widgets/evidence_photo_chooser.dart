import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';

class EvidencePhotoChooser extends StatelessWidget {
  const EvidencePhotoChooser({
    required this.photo,
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
    super.key,
  });

  final XFile? photo;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(photo?.name ?? 'Ninguna imagen seleccionada'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: enabled ? onCamera : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? onGallery : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
