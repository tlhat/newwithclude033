import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:haneen_kids_vod/app/app_theme.dart';
import 'package:haneen_kids_vod/core/services/calm_voice_service.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/shared/components/app_state_manager.dart';

enum StudioCategory {
  gender,
  face,
  hair,
  outfit,
  background,
  pose,
  accessory,
}

class CharacterStudioScreen extends StatefulWidget {
  final AppStateManager appState;

  const CharacterStudioScreen({
    super.key,
    required this.appState,
  });

  @override
  State<CharacterStudioScreen> createState() => _CharacterStudioScreenState();
}

class _CharacterStudioScreenState extends State<CharacterStudioScreen> {
  late AvatarCustomizationModel _currentAvatar;
  StudioCategory _selectedCategory = StudioCategory.gender;
  bool _isSaving = false;
  CompanionViewAngle _viewAngle = CompanionViewAngle.front;

  @override
  void initState() {
    super.initState();
    final child = widget.appState.currentAccount?.activeChild;
    if (child != null) {
      _currentAvatar = child.companionAvatar.copyWith();
    } else {
      _currentAvatar = AvatarCustomizationModel();
    }
  }

  void _onSelectGender(CompanionGender newGender) {
    if (_currentAvatar.gender == newGender) return;
    setState(() {
      final defaultHair = newGender == CompanionGender.boy ? 'curly' : 'ponytail';
      _currentAvatar = _currentAvatar.copyWith(
        gender: newGender,
        hairStyle: defaultHair,
      );
    });
  }

  Future<void> _handleItemTap(CatalogItem item) async {
    final child = widget.appState.currentAccount?.activeChild;
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final itemName = isAr ? item.labelAr : item.labelEn;

    if (_currentAvatar.isItemUnlocked(item.id)) {
      _applyItemSelection(item.id);
      return;
    }

    if (!widget.appState.isCompanionShopEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.companionShopDisabled),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (child == null || child.starsEarned < item.starsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.companionNotEnoughStars),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⭐ ', style: TextStyle(fontSize: 22)),
            Expanded(child: Text(l10n.companionUnlockTitle)),
          ],
        ),
        content: Text(l10n.companionUnlockPrompt(itemName, item.starsCost)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignTokens.rewardGold,
              foregroundColor: Colors.black87,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.companionUnlockButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bool unlocked = await widget.appState.unlockCompanionItem(
        item.id,
        item.starsCost,
      );
      if (unlocked && mounted) {
        setState(() {
          if (!_currentAvatar.unlockedItems.contains(item.id)) {
            _currentAvatar.unlockedItems.add(item.id);
          }
          _applyItemSelection(item.id);
        });
        CalmVoiceService.instance.speakCalmly(
          isAr
              ? tr('مبروك يا بطل! تم فتح {0} بنجاح!', [itemName])
              : 'Awesome! $itemName unlocked successfully!',
          allowSpeechForRepeatGame: true,
        );
      }
    }
  }

  void _applyItemSelection(String itemId) {
    setState(() {
      switch (_selectedCategory) {
        case StudioCategory.gender:
          break;
        case StudioCategory.face:
          final bool isExpression = AvatarCustomizationModel.kFaceExpressions
              .any((e) => e.id == itemId);
          _currentAvatar = isExpression
              ? _currentAvatar.copyWith(
                  faceExpression: CompanionFaceExpression.fromJson(itemId))
              : _currentAvatar.copyWith(skinTone: itemId);
          break;
        case StudioCategory.hair:
          _currentAvatar = _currentAvatar.copyWith(hairStyle: itemId);
          break;
        case StudioCategory.outfit:
          _currentAvatar = _currentAvatar.copyWith(outfit: itemId);
          break;
        case StudioCategory.background:
          _currentAvatar = _currentAvatar.copyWith(background: itemId);
          break;
        case StudioCategory.pose:
          _currentAvatar = _currentAvatar.copyWith(
            pose: CompanionPose.fromJson(itemId),
          );
          break;
        case StudioCategory.accessory:
          _currentAvatar = _currentAvatar.copyWith(accessory: itemId);
          break;
      }
    });
  }

  Future<void> _saveAndExit() async {
    setState(() => _isSaving = true);
    final child = widget.appState.currentAccount?.activeChild;
    if (child != null) {
      child.gender = _currentAvatar.gender.name;
    }
    await widget.appState.saveCompanionAvatar(_currentAvatar);

    if (mounted) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      CalmVoiceService.instance.speakCalmly(
        isAr
            ? tr('شخصيتك رائعة جداً! سأكون معك دائماً في كل مغامرات حنين!')
            : 'Your character looks amazing! I will accompany you everywhere!',
        allowSpeechForRepeatGame: true,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final child = widget.appState.currentAccount?.activeChild;
    final int stars = child?.starsEarned ?? 0;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companionStudioTitle),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppDesignTokens.rewardGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppDesignTokens.rewardGold, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$stars',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppDesignTokens.rewardGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double previewSize = (constraints.maxHeight * 0.32).clamp(140.0, 220.0);

            return Column(
              children: [
                // Top Live Character Preview
                SizedBox(
                  height: previewSize + 16,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HaneenCompanionAvatarWidget(
                          avatar: _currentAvatar,
                          mode: CompanionDisplayMode.fullBody,
                          size: previewSize,
                          viewAngle: _viewAngle,
                          animateBreathing: true,
                          onTap: () {
                            CalmVoiceService.instance.speakCalmly(
                              isAr
                                  ? tr('أنا شخصيتك المرافقة! اختر لي أجمل الملابس والتسريحات.')
                                  : 'I am your companion! Choose the coolest styles for me.',
                              allowSpeechForRepeatGame: true,
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        // View-angle toggle: front vs 3/4 view of the 3D sprite
                        SizedBox(
                          height: 28,
                          child: SegmentedButton<CompanionViewAngle>(
                            segments: [
                              ButtonSegment(
                                value: CompanionViewAngle.front,
                                label: Text(isAr ? tr('أمامي') : 'Front', style: const TextStyle(fontSize: 10)),
                                icon: const Icon(Icons.face, size: 14),
                              ),
                              ButtonSegment(
                                value: CompanionViewAngle.threeQuarter,
                                label: Text(isAr ? tr('مائل') : '3/4', style: const TextStyle(fontSize: 10)),
                                icon: const Icon(Icons.threed_rotation, size: 14),
                              ),
                            ],
                            selected: {_viewAngle},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              setState(() => _viewAngle = selection.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Selection Tabs
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildCategoryChip(
                        category: StudioCategory.gender,
                        icon: _currentAvatar.gender == CompanionGender.boy ? '👦' : '👧',
                        label: l10n.companionCategoryGender,
                      ),
                      _buildCategoryChip(
                        category: StudioCategory.face,
                        icon: '🎨',
                        label: l10n.companionCategoryFace,
                      ),
                      _buildCategoryChip(
                        category: StudioCategory.hair,
                        icon: '💇',
                        label: l10n.companionCategoryHair,
                      ),
                      _buildCategoryChip(
                        category: StudioCategory.outfit,
                        icon: '👕',
                        label: l10n.companionCategoryOutfit,
                      ),
                      _buildCategoryChip(
                        category: StudioCategory.background,
                        icon: '🏞️',
                        label: l10n.companionCategoryBackground,
                      ),
                      _buildCategoryChip(
                        category: StudioCategory.pose,
                        icon: '💃',
                        label: l10n.companionCategoryPose,
                      ),
                      _buildCategoryChip(
                        category: StudioCategory.accessory,
                        icon: '👑',
                        label: isAr ? tr('الإضافات') : 'Extras',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Options Grid
                Expanded(
                  child: Container(
                    color: Theme.of(context).cardColor.withOpacity(0.3),
                    padding: const EdgeInsets.all(8),
                    child: _buildOptionsList(isAr),
                  ),
                ),

                // Bottom Save Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignTokens.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveAndExit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.companionSaveButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required StudioCategory category,
    required String icon,
    required String label,
  }) {
    final bool isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        avatar: Text(icon, style: const TextStyle(fontSize: 14)),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppDesignTokens.primaryPurple.withOpacity(0.25),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppDesignTokens.primaryPurple : Colors.white24,
          width: isSelected ? 1.5 : 1.0,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = category);
          }
        },
      ),
    );
  }

  Widget _buildOptionsList(bool isAr) {
    if (_selectedCategory == StudioCategory.gender) {
      return Center(
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderCard(
                gender: CompanionGender.boy,
                icon: '👦',
                title: isAr ? tr('ولد') : 'Boy',
                subtitle: isAr ? tr('بطل المغامرات') : 'Hero Boy',
              ),
              const SizedBox(width: 12),
              _buildGenderCard(
                gender: CompanionGender.girl,
                icon: '👧',
                title: isAr ? tr('بنت') : 'Girl',
                subtitle: isAr ? tr('بطلة الذكاء') : 'Clever Girl',
              ),
            ],
          ),
        ),
      );
    }

    List<CatalogItem> items;
    String currentSelectedId;

    switch (_selectedCategory) {
      case StudioCategory.face:
        items = [
          ...AvatarCustomizationModel.kFaceExpressions,
          ...AvatarCustomizationModel.kSkinTones,
        ];
        currentSelectedId = _currentAvatar.skinTone;
        break;
      case StudioCategory.hair:
        items = _currentAvatar.gender == CompanionGender.boy
            ? AvatarCustomizationModel.kBoyHairStyles
            : AvatarCustomizationModel.kGirlHairStyles;
        currentSelectedId = _currentAvatar.hairStyle;
        break;
      case StudioCategory.outfit:
        items = AvatarCustomizationModel.kOutfits;
        currentSelectedId = _currentAvatar.outfit;
        break;
      case StudioCategory.background:
        items = AvatarCustomizationModel.kBackgrounds;
        currentSelectedId = _currentAvatar.background;
        break;
      case StudioCategory.pose:
        items = AvatarCustomizationModel.kPoses;
        currentSelectedId = _currentAvatar.pose.name;
        break;
      case StudioCategory.accessory:
        items = AvatarCustomizationModel.kAccessories;
        currentSelectedId = _currentAvatar.accessory;
        break;
      default:
        items = [];
        currentSelectedId = '';
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.05,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isSelected = item.id == currentSelectedId ||
            (_selectedCategory == StudioCategory.face &&
                item.id == _currentAvatar.faceExpression.name);
        final bool isUnlocked = _currentAvatar.isItemUnlocked(item.id);

        return InkWell(
          onTap: () => _handleItemTap(item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppDesignTokens.primaryPurple.withOpacity(0.18)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppDesignTokens.primaryPurple
                    : (isUnlocked ? Colors.white12 : Colors.orange.withOpacity(0.4)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  item.previewEmoji ?? '✨',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? item.labelAr : item.labelEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppDesignTokens.primaryPurple : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (!isUnlocked)
                        Row(
                          children: [
                            const Text('🔒 ', style: TextStyle(fontSize: 9)),
                            Text(
                              '${item.starsCost} ⭐',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppDesignTokens.rewardGold,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          isAr ? tr('مفتوح') : 'Unlocked',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppDesignTokens.primaryPurple,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderCard({
    required CompanionGender gender,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = _currentAvatar.gender == gender;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onSelectGender(gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppDesignTokens.primaryPurple.withOpacity(0.18)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppDesignTokens.primaryPurple : Colors.white12,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppDesignTokens.primaryPurple : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
