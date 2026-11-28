import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/features/development/dev_cards.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class VerticalVideoFeedPlayerScreen extends StatefulWidget {
  final AppStateManager appState;
  final bool embeddedInShell;

  /// False while another bottom-nav section is on screen, so the current
  /// video / story pauses.
  final bool tabActive;
  final VoidCallback? onNavigateToGames;
  final VoidCallback? onNavigateToAcademy;
  const VerticalVideoFeedPlayerScreen({
    super.key,
    required this.appState,
    this.embeddedInShell = false,
    this.tabActive = true,
    this.onNavigateToGames,
    this.onNavigateToAcademy,
  });

  static int resolveDisplayedVideoIndexById(
    List<VideoModel> displayedVideos,
    String targetVideoId,
  ) {
    return displayedVideos.indexWhere((v) => v.id == targetVideoId);
  }

  @override
  State<VerticalVideoFeedPlayerScreen> createState() =>
      _VerticalVideoFeedPlayerScreenState();
}

class _VerticalVideoFeedPlayerScreenState
    extends State<VerticalVideoFeedPlayerScreen> {
  final PageController _pageController = PageController();
  String _selectedCategory = 'all';
  int _currentVideoIndex = 0;
  bool _showTimedExplorationPopup = true;
  Timer? _explorationPopupTimer;

  @override
  void initState() {
    super.initState();
    _scheduleFiveSecondExplorationPopup();
    // Phase 5: contextual companion greeting, presented once per child
    // session (duplicate-safe across rebuilds/navigation; speech only when
    // mute/TTS/parental-lock/speaking guards allow).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.appState.hasSelectedChildInSession) {
        widget.appState.presentCompanionGreetingOnce();
      }
    });
  }

  void _scheduleFiveSecondExplorationPopup() {
    _explorationPopupTimer?.cancel();
    if (!widget.appState.featureFlags.enableTimedExplorationPopup) {
      _showTimedExplorationPopup = false;
      return;
    }
    _showTimedExplorationPopup = true;
    _explorationPopupTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTimedExplorationPopup = false;
        });
      }
    });
  }

  List<VideoModel> get _filteredVideos {
    final child = widget.appState.currentAccount?.activeChild;
    final bool offlineOnly = child?.offlineOnlyMode ?? false;
    final bool allowExternal = child?.allowExternalVideos ?? true;

    final allowedList = widget.appState.videos.where((v) {
      if (!v.isApprovedByParent || v.isBrokenStream) {
        return false;
      }
      final String u = v.streamUrl.trim();
      final bool isLocalFile = AppNetworkPolicyGuard.isSafeLocalFilePath(u);
      final bool isBuiltInSafeSample = u
          .toLowerCase()
          .startsWith('https://flutter.github.io/assets-for-api-docs/');
      if (offlineOnly && !isLocalFile) {
        return false;
      }
      if (!allowExternal && !isLocalFile && !isBuiltInSafeSample) {
        return false;
      }
      if (!isLocalFile &&
          !AppNetworkPolicyGuard.isTrustedHttpsVideoOrFeedUrl(u)) {
        return false;
      }
      return true;
    }).toList();

    if (_selectedCategory == 'all') return allowedList;
    return allowedList.where((v) => v.category == _selectedCategory).toList();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentVideoIndex = index;
    });
    final videos = _filteredVideos;
    final String? title =
        (index >= 0 && index < videos.length) ? videos[index].title : null;
    widget.appState.recordVideoTransitionWatched(videoTitle: title);
  }

  void _openBrainGamesHub() {
    if (widget.embeddedInShell && widget.onNavigateToGames != null) {
      widget.onNavigateToGames!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DevGate(appState: widget.appState, child: BrainGamesHubScreen(appState: widget.appState)),
      ),
    );
  }

  void _openHaneenAcademy({int initialTab = 0}) {
    if (widget.embeddedInShell && widget.onNavigateToAcademy != null) {
      widget.onNavigateToAcademy!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HaneenAcademyScreen(
          appState: widget.appState,
          initialTabIndex: initialTab,
        ),
      ),
    );
  }

  void _jumpToSuggestedVideo(VideoModel target) {
    int idx = VerticalVideoFeedPlayerScreen.resolveDisplayedVideoIndexById(
      _filteredVideos,
      target.id,
    );
    if (idx == -1 && _selectedCategory != 'all') {
      setState(() {
        _selectedCategory = 'all';
      });
      idx = VerticalVideoFeedPlayerScreen.resolveDisplayedVideoIndexById(
        _filteredVideos,
        target.id,
      );
    }
    if (idx == -1) return;
    setState(() {
      _currentVideoIndex = idx;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(idx);
      }
    });
  }

  void _openSmartVoiceAssistantModal() {
    final child = widget.appState.currentAccount?.activeChild;
    final String childName = child?.name ?? 'بطل حنين';
    widget.appState.triggerVoiceAssistantGreetingAndSuggestion();

    showModalBottomSheet(
      context: context,
    useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final suggested = widget.appState.suggestedVideoForChild ??
                widget.appState.videos.first;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF14B8A6), width: 2),
                        ),
                        child: const Text('🤖💬',
                            style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رفيق حنين — نصوص عائمة (${childName})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'يظهر رسائل تشجيعية ونصائح عائمة هادئة على الشاشة بدون صوت',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF14B8A6)),
                    ),
                    child: Text(
                      widget.appState.currentAssistantBannerMessage,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '✨ القصة المقترحة لك الآن:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: ListTile(
                      leading: Text(suggested.emoji,
                          style: const TextStyle(fontSize: 34)),
                      title: Text(
                        suggested.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${VideoModel.getCategoryDisplayLabel(suggested.category)} • ${suggested.ageGroup}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _jumpToSuggestedVideo(suggested);
                        },
                        child: Text('شاهد الآن'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '🎧 اطلب من المساعد الصوتي أن يساعدك:',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        avatar: const Text('🌙'),
                        label: Text('اقترح قصة نوم هادئة'),
                        onPressed: () {
                          final bedtimeVideo =
                              widget.appState.videos.firstWhere(
                            (v) => v.category == 'bedtime',
                            orElse: () => widget.appState.videos.first,
                          );
                          setModalState(() {
                            widget.appState.suggestedVideoForChild =
                                bedtimeVideo;
                            widget.appState.currentAssistantBannerMessage =
                                'اخترت لك قصة النوم الهادئة «${bedtimeVideo.title}». تنفس بعمق واستمع بهدوء يا ${childName}.';
                          });
                          CalmVoiceService.instance.speakCalmly(
                            widget.appState.currentAssistantBannerMessage,
                          );
                        },
                      ),
                      ActionChip(
                        backgroundColor: Color(0xFF0F172A),
                        avatar: Text('🗣️'),
                        label: Text('دربني على جملة عربية فصيحة'),
                        onPressed: () {
                          final arabicVideo = widget.appState.videos.firstWhere(
                            (v) => v.category == 'arabic',
                            orElse: () => widget.appState.videos.first,
                          );
                          setModalState(() {
                            widget.appState.suggestedVideoForChild =
                                arabicVideo;
                            widget.appState.currentAssistantBannerMessage =
                                'هيا نردد معاً بهدوء: ${arabicVideo.repeatPhrase}';
                          });
                          CalmVoiceService.instance.speakCalmly(
                            'هيا نردد معاً بهدوء يا ${childName}: ${arabicVideo.repeatPhrase}',
                            rate: 0.34,
                          );
                        },
                      ),
                      ActionChip(
                        backgroundColor: Color(0xFF0F172A),
                        avatar: Text('🧘'),
                        label: Text('تمرين التنفس والهدوء'),
                        onPressed: () {
                          final String calmBreathing =
                              'يا بطل حنين، خذ شهيقاً عميقاً وهادئاً من أنفك كأنك تشم وردة جميلة... والآن أخرج الهواء ببطء وابتسم!';
                          setModalState(() {
                            widget.appState.currentAssistantBannerMessage =
                                calmBreathing;
                          });
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        avatar: const Text('🎓'),
                        label: Text('افتح أكاديمية حنين التعليمية'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openHaneenAcademy(initialTab: 0);
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        avatar: const Text('📖'),
                        label: Text('اقرأ لي قصة تفاعلية'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openHaneenAcademy(initialTab: 1);
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF0F172A),
                        avatar: Text('🗺️'),
                        label: Text('خريطة النجوم والمكافآت'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openHaneenAcademy(initialTab: 2);
                        },
                      ),
                      ActionChip(
                        backgroundColor: Color(0xFF0F172A),
                        avatar: Text('❓'),
                        label: Text('اسألني سؤالاً علمياً بسيطاً'),
                        onPressed: () {
                          List<String> safeQaList = [
                            '🦋 سؤال وجواب: لماذا تطير الفراشة بين الأزهار؟ لجمع الرحيق اللذيذ ومساعدة النباتات على النمو!',
                            '🌞 سؤال وجواب: ما فائدة الشمس صباحاً؟ تمنحنا الدفء والضوء وتساعد النباتات الخضراء على النمو!',
                            '🦷 سؤال وجواب: لماذا نغسل أسناننا قبل النوم؟ لنحافظ عليها نظيفة وقوية وبيضاء كاللؤلؤ!',
                            '🛡️ تذكير الأمان: أنا رفيق تعليمي داخل التطبيق؛ لا أطلب أبداً اسمك الكامل أو عنوانك أو مدرستك، وإذا خطر ببالك سؤال كبير فاسأل ماما أو بابا دائماً!',
                          ];
                          final nextQa = safeQaList[
                              DateTime.now().second % safeQaList.length];
                          setModalState(() {
                            widget.appState.currentAssistantBannerMessage =
                                nextQa;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openRealWorldHeroActivityModal(VideoModel item) {
    CalmVoiceService.instance.speakCalmly(
      'نشاط البطل الواقعي: ${item.activeActivity}',
      rate: 0.38,
    );

    showModalBottomSheet(
      context: context,
    useSafeArea: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text(
                'نافذة «نشاط البطل الواقعي»',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'مهمة حركية وتربوية ممتعة لتقوم بها خارج الشاشة الآن:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  item.activeActivity,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    widget.appState
                        .awardStarAndRecordActivity('activity_${item.id}');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '🌟 بطل حقيقي! أضفنا نجمة جديدة إلى رصيدك بعد إنجاز النشاط!'),
                        backgroundColor: Color(0xFFF59E0B),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: Text(
                    'أنجزت النشاط الواقعي! (+1 نجمة ⭐)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openParentalGateDialog({int initialTab = 0}) {
    CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    final random = Random();
    final int a = random.nextInt(6) + 4;
    final int b = random.nextInt(5) + 3;
    final int expected = a * b;
    final TextEditingController answerCtrl = TextEditingController();
    String? gateError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بوابة الوالدين المحمية',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'للدخول إلى بوابة الوالدين، يرجى إدخال الرمز السري للوالدين (المكوّن من ٦ أرقام):',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: answerCtrl,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'أدخل الرمز السري (٦ أرقام)',
                      counterText: '',
                    ),
                  ),
                  if (gateError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      gateError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء',
                      style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final acc = widget.appState.currentAccount;
                    if (acc == null) return;
                    if (acc.isPinLockedOut) {
                      setDialogState(() {
                        gateError =
                            '⏳ تم قفل البوابة مؤقتاً بسبب محاولات خاطئة. انتظر ${acc.remainingPinLockoutSeconds} ثانية.';
                      });
                      return;
                    }
                    final input = answerCtrl.text.trim();
                    final bool pinValid = acc.verifyParentalPin(input);
                    if (pinValid) {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentalStudioScreen(
                            appState: widget.appState,
                            initialTabIndex: initialTab,
                          ),
                        ),
                      );
                    } else {
                      setDialogState(() {
                        gateError = acc.isPinLockedOut
                            ? '⏳ تم قفل البوابة مؤقتاً لمدة ${acc.remainingPinLockoutSeconds} ثانية لحماية طفلك.'
                            : 'رمز PIN الأبوي غير صحيح.';
                      });
                    }
                  },
                  child: Text('دخول استوديو الوالدين'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _explorationPopupTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.appState.currentAccount;
    if (account == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final activeChild = account.activeChild;
    final videos = _filteredVideos;
    final bool sleepCurtainActive = widget.appState.isDailyLimitReached;
    const bool subscriptionExpired = false;
    final bool remotelyLockedByParent = activeChild.isDeviceRemotelyLocked;

    return Scaffold(
      body: Stack(
        children: [
          if (videos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: const Color(0xFF14B8A6).withOpacity(0.6),
                        width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌈🧸✨', style: TextStyle(fontSize: 54)),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد قصص مرئية في هذا القسم الآن يا بطل!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'يمكنك استكشاف دروس «أكاديمية حنين» المصورة أو اللعب في واحة اللعب والتعلم ريثما نعود للقصص!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          if (_selectedCategory != 'all')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14B8A6),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedCategory = 'all'),
                              icon: const Icon(Icons.video_library_rounded),
                              label: Text('عرض كل القصص'),
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _openHaneenAcademy(initialTab: 0),
                            icon: const Icon(Icons.school_rounded),
                            label: Text('أكاديمية حنين 🎓'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA855F7),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _openBrainGamesHub,
                            icon: const Icon(Icons.psychology_rounded),
                            label: Text('ألعاب الذكاء 🧠'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = videos[index];
                final isCurrentPage = index == _currentVideoIndex &&
                    widget.tabActive &&
                    !sleepCurtainActive &&
                    !subscriptionExpired &&
                    !remotelyLockedByParent;
                return VerticalVideoFeedItemWidget(
                  key: ValueKey('${item.id}_$index'),
                  video: item,
                  isActive: isCurrentPage,
                  onLikeTap: () => widget.appState.toggleLikeVideo(item),
                  onHeroActivityTap: () =>
                      _openRealWorldHeroActivityModal(item),
                  onVoiceAssistantTap: _openSmartVoiceAssistantModal,
                  onBrainGamesTap: _openBrainGamesHub,
                  onAcademyTap: () => _openHaneenAcademy(initialTab: 0),
                );
              },
            ),

          if (account.warmEveningFilter)
            IgnorePointer(
              child: Container(
                color: const Color(0xFFFF8F00).withOpacity(0.20),
              ),
            ),

          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: SmoothFreeTrialStatusBanner(
                    account: account,
                    onUpgradeTap: () => _openParentalGateDialog(initialTab: 2),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Row(
                    children: [
                      if (account.isGuestDemoSession) ...[
                        GestureDetector(
                          onTap: () => widget.appState.logout(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded,
                                    size: 13, color: Colors.black87),
                                SizedBox(width: 3),
                                Text(
                                  'البداية',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      GestureDetector(
                        onTap: widget.appState.openChildProfilesScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(activeChild.chosenAvatar,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                activeChild.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.swap_horiz, size: 13),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.45),
                              width: 0.8),
                        ),
                        child: Text(
                          '⭐ ${activeChild.starsEarned}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Text(
                          '⏱️ ${activeChild.usedMinutesToday}/${activeChild.limitShown}د',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openHaneenAcademy(initialTab: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎓', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 3),
                              Text(
                                'الأكاديمية (${activeChild.completedLessons.length})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _openBrainGamesHub,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withOpacity(0.82),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🧠', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 3),
                              Text(
                                'الذكاء (${activeChild.intelligencePoints})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _openSmartVoiceAssistantModal,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assistant_rounded,
                            size: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => widget.appState.toggleWarmEveningFilter(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: account.warmEveningFilter
                                ? const Color(0xFFF59E0B)
                                : Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Icon(
                            Icons.wb_twilight_rounded,
                            size: 14,
                            color: account.warmEveningFilter
                                ? Colors.black87
                                : Colors.white,
                          ),
                        ),
                      ),
                      if (!account.isGuestDemoSession) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _openParentalGateDialog(initialTab: 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'الوالدين',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(
                  height: 28,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: kVideoCategories.length,
                    itemBuilder: (ctx, i) {
                      final cat = kVideoCategories[i];
                      final isSelected = _selectedCategory == cat['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['id']!;
                            _currentVideoIndex = 0;
                          });
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(0);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF14B8A6)
                                : Colors.black.withOpacity(0.38),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF14B8A6)
                                  : Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${cat['icon']} ${cat['title']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),



                // Immediate Non-Distracting Navigation for: أكاديمية حنين (Haneen Academy), القصص (Stories), الألعاب (Games) with brief descriptive labels
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openHaneenAcademy(initialTab: 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF065F46), Color(0xFF0F172A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF10B981), width: 1.2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🎓 أكاديمية حنين',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'تعلم الحروف والأرقام',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFFA7F3D0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'all';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF0F766E)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF14B8A6), width: 1.6),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '📖 القصص',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'قصص مصورة متحركة',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFFFDE68A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: _openBrainGamesHub,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4C1D95), Color(0xFF0F172A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFC084FC), width: 1.2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🎮 الألعاب',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ألعاب ذكاء وتفكير',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFFE9D5FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5-Second Timed Visual Pop-Up Suggestion ("ما رأيك أن نلعب ونتعلم؟") that fades away after 5s and opens Games when tapped
                AnimatedOpacity(
                  opacity: _showTimedExplorationPopup ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 450),
                  child: _showTimedExplorationPopup
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: GestureDetector(
                            onTap: _openBrainGamesHub,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55F59E0B),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text('🎮✨',
                                      style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ما رأيك أن نلعب ونتعلم؟',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'اضغط هنا للانتقال فوراً إلى قسم الألعاب الممتعة!',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 15, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                  child: CuteSuperheroCompanionBanner(
                    appState: widget.appState,
                    compactMode: true,
                  ),
                ),
              ],
            ),
          ),

          if (sleepCurtainActive)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌙💤✨', style: TextStyle(fontSize: 68)),
                      const SizedBox(height: 20),
                      Text(
                        'ستارة النوم الهادئة — تصبح على خير يا ${activeChild.name}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'انتهت حصتك اليومية (${activeChild.limitShown} دقيقة) بهدوء، وجمعت ⭐ ${activeChild.starsEarned} نجوم رائعة! حان الآن وقت إراحة العينين والاستعداد للنوم الجميل.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openParentalGateDialog(initialTab: 2),
                        icon: const Icon(Icons.lock_open),
                        label: Text(
                          'بوابة الوالدين (لتمديد الوقت أو تغيير الطفل)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!AppStateManager.isAppCompletelyFreeForever && subscriptionExpired && !sleepCurtainActive)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎁👑', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        'انتهت فترة التجربة المجانية الشاملة (٧ أيام)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'استمتع طفلك بقصص حنين الهادئة والمصحح الصوتي! يمكنك الآن اختيار الباقة المرنة الأنسب لعائلتك والدفع بسهولة عبر فودافون كاش أو أورنج كاش أو اتصالات كاش أو إنستا باي أو فيزا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openParentalGateDialog(initialTab: 2),
                        icon: const Icon(Icons.workspace_premium),
                        label: Text(
                          'الباقات',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (remotelyLockedByParent)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF31102F), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.phonelink_lock_rounded,
                          size: 68,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '🔒 تم قفل شاشة الموبايل عن بُعد يا ${activeChild.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          activeChild.remoteLockReasonMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openParentalGateDialog(initialTab: 0),
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(
                          'فتح القفل الأبوي (بوابة الوالدين / الرمز السري)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
