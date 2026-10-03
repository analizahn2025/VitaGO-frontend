import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    required this.page,
    required this.totalItems,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int page;
  final int totalItems;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$totalItems registros · Página $page',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: hasPrevious ? onPrevious : null,
            tooltip: 'Página anterior',
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: hasNext ? onNext : null,
            tooltip: 'Página siguiente',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
