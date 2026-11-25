import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Destination 5: حسابي / My Account
class ChildAccountTab extends StatelessWidget {
  final AppStateManager appState;
  final VoidCallback onOpenParentalGate;

  const ChildAccountTab({
    super.key,
    required this.appState,
    required this.onOpenParentalGate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = appState.currentAccount;
    final child = account?.activeChild;
    final theme = Theme.of(context);

    if (account == null || child == null) {
      return const AppSkeletonBox(height: 180);
    }

    final double usageRatio = child.dailyTimeLimit > 0
        ? (child.usedMinutesToday / child.dailyTimeLimit).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppDesignTokens.primaryPurple.withOpacity(0.18),
                        child: Text(
                          child.chosenAvatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.ageGroupAndLevel(
                                child.age,
                                child.educationLevel,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
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
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CharacterStudioScreen(appState: appState),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                    child: Row(
                      children: [
                        HaneenCompanionAvatarWidget(
                          avatar: child.companionAvatar,
                          mode: CompanionDisplayMode.bust,
                          size: 56,
                          animateBreathing: true,
                        ),
                        const SizedBox(width: AppDesignTokens.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.companionStudioTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.companionCustomizeButton,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppDesignTokens.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesignTokens.primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(40, 36),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CharacterStudioScreen(appState: appState),
                              ),
                            );
                          },
                          icon: const Icon(Icons.palette_rounded, size: 16),
                          label: Text(
                            l10n.companionCategoryGender,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              l10n.dailyUsageLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.minutesProgress(
                                child.usedMinutesToday,
                                child.dailyTimeLimit,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusPill),
                        child: LinearProgressIndicator(
                          value: usageRatio,
                          minHeight: 10,
                          color: AppDesignTokens.secondaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),
              GoogleBackupCard(appState: appState),
              const SizedBox(height: AppDesignTokens.spaceMd),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        appState.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppDesignTokens.primaryPurple,
                      ),
                      title: Text(l10n.darkModeTitle),
                      subtitle: Text(l10n.darkModeSubtitle),
                      value: appState.isDarkMode,
                      onChanged: (val) => appState.toggleDarkMode(val),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      minVerticalPadding: 14,
                      leading: const Icon(
                        Icons.switch_account_rounded,
                        color: AppDesignTokens.infoBlue,
                      ),
                      title: Text(l10n.switchChildTitle),
                      subtitle: Text(
                        l10n.registeredProfilesCount(account.children.length),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MultiChildProfilesScreen(
                              appState: appState,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceLg),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignTokens.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(
                    double.infinity,
                    AppDesignTokens.minTouchTarget + 6,
                  ),
                ),
                onPressed: onOpenParentalGate,
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: Text(l10n.parentalGateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
