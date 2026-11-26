import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Destination 4: إنجازاتي / My Achievements
class AchievementsCenterTab extends StatelessWidget {
  final AppStateManager appState;
  final VoidCallback? onExploreAcademy;

  const AchievementsCenterTab({
    super.key,
    required this.appState,
    this.onExploreAcademy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final child = appState.currentAccount?.activeChild;
    final theme = Theme.of(context);
    if (child == null) {
      return const AppSkeletonBox(height: 180);
    }

    final int stars = child.starsEarned;
    final int iqPoints = child.intelligencePoints;
    final int completedLessons = child.completedLessons.length;
    final int badgesCount = child.unlockedAchievements.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.achievementsTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                  child: Row(
                    children: [
                      HaneenCompanionAvatarWidget(
                        avatar: child.companionAvatar,
                        mode: CompanionDisplayMode.bust,
                        size: 54,
                        isCelebrating: true,
                        animateBreathing: true,
                      ),
                      const SizedBox(width: AppDesignTokens.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.greatJobChild(child.name),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.achievementsSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),
              Wrap(
                spacing: AppDesignTokens.spaceSm,
                runSpacing: AppDesignTokens.spaceSm,
                children: [
                  _MetricTile(
                    icon: Icons.star_rounded,
                    color: AppDesignTokens.rewardGold,
                    value: '$stars',
                    label: l10n.starsEarnedLabel,
                  ),
                  _MetricTile(
                    icon: Icons.psychology_rounded,
                    color: AppDesignTokens.primaryPurple,
                    value: '$iqPoints',
                    label: l10n.iqPointsLabel,
                  ),
                  _MetricTile(
                    icon: Icons.menu_book_rounded,
                    color: AppDesignTokens.secondaryGreen,
                    value: '$completedLessons',
                    label: l10n.completedLessonsLabel,
                  ),
                  _MetricTile(
                    icon: Icons.military_tech_rounded,
                    color: AppDesignTokens.infoBlue,
                    value: '$badgesCount',
                    label: l10n.unlockedBadgesLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppDesignTokens.spaceLg),
              Text(
                l10n.unlockedBadgesHeading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceSm),
              if (child.unlockedAchievements.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.noBadgesYet),
                        if (onExploreAcademy != null) ...[
                          const SizedBox(height: AppDesignTokens.spaceSm),
                          ElevatedButton.icon(
                            onPressed: onExploreAcademy,
                            icon: const Icon(Icons.school_rounded),
                            label: Text(l10n.goToAcademy),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                ...child.unlockedAchievements.entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(
                      bottom: AppDesignTokens.spaceXs,
                    ),
                    child: ListTile(
                      leading: Text(
                        badgeById(entry.key)?.emoji ?? '🏅',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        badgeTitleAr(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${badgeById(entry.key)?.descriptionAr ?? ''}\n${l10n.badgeUnlockedAt(badgeDateShort(entry.value.toString()))}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth =
        (MediaQuery.of(context).size.width -
                (AppDesignTokens.spaceMd * 2) -
                AppDesignTokens.spaceSm) /
            2;
    return SizedBox(
      width: cardWidth.clamp(130.0, 260.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
