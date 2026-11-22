import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/app/app_theme.dart';

/// Skeleton loading placeholder used in place of blank screens while loading data.
class AppSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 72,
    this.borderRadius = AppDesignTokens.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Clear empty / offline state banner with a large >=48dp retry button.
class AppOfflineRetryBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppOfflineRetryBanner({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: AppDesignTokens.infoBlue,
            ),
            const SizedBox(height: AppDesignTokens.spaceSm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spaceXs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDesignTokens.spaceMd),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
