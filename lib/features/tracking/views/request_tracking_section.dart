import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/features/tracking/controllers/tracking_controller.dart';

class RequestTrackingSection extends ConsumerStatefulWidget {
  const RequestTrackingSection({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<RequestTrackingSection> createState() =>
      _RequestTrackingSectionState();
}

class _RequestTrackingSectionState
    extends ConsumerState<RequestTrackingSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(requestTrackingControllerProvider(widget.requestId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(
      requestTrackingControllerProvider(widget.requestId),
    );
    return tracking.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => ref.invalidate(
            requestTrackingControllerProvider(widget.requestId),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar seguimiento'),
        ),
      ),
      data: (value) {
        final point = value.location;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  value.available
                      ? Icons.near_me_outlined
                      : Icons.route_outlined,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.available
                            ? 'Seguimiento disponible'
                            : 'Seguimiento finalizado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        point == null
                            ? 'Todavía no hay una ubicación operativa.'
                            : '${point.latitude}, ${point.longitude}\n${AppDateFormat.dateTime(point.recordedAt)}',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(
                    requestTrackingControllerProvider(widget.requestId),
                  ),
                  tooltip: 'Actualizar seguimiento',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
