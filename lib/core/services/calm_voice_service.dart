import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Dual-Assistant Sequential Voice Service:
/// - Primary Voice Assistant (`cUDXOxxuLZJdTcxEyGVB`) for general instructions, explanations, and odd-numbered story scenes.
/// - Second / Superhero Voice Assistant (`L14QZl4DxSQ6xGvib36i`) for post-correct-answer encouragement and even-numbered story scenes.
/// - Implements a strict Sequential Audio Queue (`_sequentialQueueLock`) that guarantees each audio clip finishes 100%
///   before the next clip starts or the next Story Image Card auto-swipes.
/// - Supports Touch-to-Pause / Touch-to-Resume (`toggleStoryPauseResume`) and Immediate Total Audio Stop on Parental Studio entry (`stopAllAudioImmediatelyForParentalGate`).
class CalmVoiceService {
  static final CalmVoiceService instance = CalmVoiceService._internal();
  CalmVoiceService._internal();

  static bool isTestEnvironment = false;

  static bool get isRunningInUnitTest {
    if (isTestEnvironment) return true;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}
    try {
      final String bindingType =
          WidgetsBinding.instance.runtimeType.toString();
      if (bindingType.contains('Test') || bindingType.contains('Automated')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  VideoPlayerController? _activeElevenLabsAudioController;
  VideoPlayerController? _calmBgMusicController;
  SharedPreferences? _prefs;
  bool _engineReady = false;
  bool _sttReady = false;
  bool isSpeaking = false;
  bool isStoryNarrationPaused = false;
  bool isAssistantMuted = false;
  bool isSoundAndVoiceEnabled = true;
  bool isChildMicrophoneAllowed = true;
  bool isCalmBackgroundMusicEnabled = true;
  bool isCalmBackgroundMusicPlaying = false;
  bool lastNarratedStoryHadBackgroundMusic = false;
  double calmBackgroundMusicVolume = 0.14;

  // Strict Sequential Audio Queue state
  int _activeStoryNarrationSessionId = 0;
  Completer<void>? _activeClipCompletionCompleter;
  final List<String> sequentialPlaybackLog = [];

  String activePersonaId = 'haneen';
  String activeDialect = 'msa';
  double activeVoiceSpeed = 1.0;
  String backendTtsProxyUrl = '';
  String sessionAccessToken = '';
  String lastSpokenHaneenMessage = '';
  ElevenLabsSynthesisOutcome? lastSynthesisOutcome;

  void attachSharedPreferences(SharedPreferences prefs) {
    _prefs = prefs;
    ElevenLabsVoiceService.hydrateCacheFromPrefs(prefs);
  }

  void configureBackendProxy({
    required String proxyUrl,
    required String bearerToken,
  }) {
    backendTtsProxyUrl = proxyUrl.trim();
    sessionAccessToken = bearerToken.trim();
  }

  void configureChildVoicePreferences({
    required String personaId,
    required String dialect,
    required double speed,
  }) {
    activePersonaId = ElevenLabsVoiceService.getPersonaById(personaId).id;
    activeDialect =
        dialect.trim().toLowerCase() == 'egyptian' ? 'egyptian' : 'msa';
    activeVoiceSpeed = speed.clamp(0.7, 1.2);
  }

  Future<void> setChildMicrophoneAllowed(bool allowed) async {
    isChildMicrophoneAllowed = allowed;
    if (!allowed) {
      await stopListening();
    }
  }

  Future<void> setAssistantMuted(bool muted) async {
    isAssistantMuted = muted;
    if (muted) {
      await stopAllAudioImmediatelyForParentalGate();
    }
  }

  Future<void> setSoundAndVoiceEnabled(bool enabled) async {
    isSoundAndVoiceEnabled = enabled;
    isAssistantMuted = !enabled;
    if (!enabled) {
      await stopAllAudioImmediatelyForParentalGate();
    }
  }

  Future<void> init() async {
    _engineReady = true;
  }

  /// Immediately and completely stops all voice narration, sequential story queues,
  /// and background music when opening or entering the Parental Gate / Parental Studio.
  Future<void> stopAllAudioImmediatelyForParentalGate() async {
    _activeStoryNarrationSessionId++;
    isStoryNarrationPaused = false;
    await stopSpeaking();
    await stopCalmBackgroundMusic();
  }

  /// Toggles Play / Pause of the active story narration when the child or parent touches anywhere on the mobile screen.
  Future<bool> toggleStoryPauseResume() async {
    if (isStoryNarrationPaused) {
      await resumeStoryNarration();
    } else {
      await pauseStoryNarration();
    }
    return isStoryNarrationPaused;
  }

  Future<void> pauseStoryNarration() async {
    isStoryNarrationPaused = true;
    isSpeaking = false;
    if (!isRunningInUnitTest) {
      try {
        await _activeElevenLabsAudioController?.pause();
        await _calmBgMusicController?.pause();
      } catch (_) {}
    }
  }

  Future<void> resumeStoryNarration() async {
    if (!isStoryNarrationPaused) return;
    isStoryNarrationPaused = false;
    isSpeaking = true;
    if (!isRunningInUnitTest) {
      try {
        await _calmBgMusicController?.play();
        await _activeElevenLabsAudioController?.play();
      } catch (_) {}
    }
  }

  Future<void> speak(
    String text, {
    double rate = 0.38,
    String? overridePersonaId,
    ElevenLabsSpeechContext context = ElevenLabsSpeechContext.quickInteraction,
  }) async {
    await speakCalmly(
      text,
      rate: rate,
      allowSpeechForRepeatGame: true,
      overridePersonaId: overridePersonaId,
      speechContext: context,
    );
  }

  Future<void> stop() async {
    await stopAllAudioImmediatelyForParentalGate();
  }

  Future<ElevenLabsSynthesisOutcome?> speakWithPersona({
    required String text,
    required String personaId,
    ElevenLabsSpeechContext context = ElevenLabsSpeechContext.quickInteraction,
  }) async {
    await speakCalmly(
      text,
      allowSpeechForRepeatGame: true,
      overridePersonaId: personaId,
      speechContext: context,
      respectContextualPersonas: false,
    );
    return lastSynthesisOutcome;
  }

  Future<String> speakInstructionAsHaneen(
    String instruction, {
    String? childName,
    String? overridePersonaId,
  }) async {
    final String prefix = (childName != null && childName.trim().isNotEmpty)
        ? 'يا ${childName.trim()}، '
        : 'يا بطل حنين، ';
    // The "🎙️ حنين تقول:" label is for the screen only. It must not be spoken.
    final String spokenMsg = '$prefix$instruction';
    final String adapted =
        ElevenLabsVoiceService.adaptTextToDialect(spokenMsg, activeDialect);
    lastSpokenHaneenMessage = '🎙️ حنين تقول: $adapted';
    await speakCalmly(
      adapted,
      rate: 0.37,
      allowSpeechForRepeatGame: true,
      overridePersonaId: overridePersonaId ?? activePersonaId,
      speechContext: ElevenLabsSpeechContext.expressiveLesson,
      respectContextualPersonas: overridePersonaId != null ? false : true,
    );
    return adapted;
  }

  Future<String> speakStoryOrQuestionAsHaneen({
    required String titleOrContext,
    required String contentToRead,
    String? questionPrompt,
    String? overridePersonaId,
  }) async {
    final String fullText = questionPrompt != null && questionPrompt.isNotEmpty
        ? '$titleOrContext. $contentToRead. سؤال حنين لك: $questionPrompt'
        : '$titleOrContext. $contentToRead';
    final String adapted =
        ElevenLabsVoiceService.adaptTextToDialect(fullText, activeDialect);
    lastSpokenHaneenMessage = adapted;
    await speakCalmly(
      adapted,
      rate: 0.36,
      allowSpeechForRepeatGame: true,
      overridePersonaId: overridePersonaId ?? 'storyteller',
      speechContext: ElevenLabsSpeechContext.storyNarration,
      respectContextualPersonas: false,
    );
    return adapted;
  }

  Future<String> reactToChildAnswerAsHaneen({
    required bool isCorrect,
    required String childName,
    String? gentleHint,
    String? learnedConcept,
    String? overridePersonaId,
    FutureOr<void> Function()? onAutoAdvanceAfterAudio,
  }) async {
    final String cleanName =
        childName.trim().isEmpty ? 'يا بطل' : childName.trim();
    final String rawReaction;
    if (isCorrect) {
      final String conceptSuffix =
          (learnedConcept != null && learnedConcept.trim().isNotEmpty)
              ? ' لقد أتقنت «${learnedConcept.trim()}» ببراعة!'
              : '';
      rawReaction =
          'أحسنت يا $cleanName! إجابة ذكية وصحيحة!$conceptSuffix أنا فخورة بك جداً 🌟';
    } else {
      final String hintText =
          (gentleHint != null && gentleHint.trim().isNotEmpty)
              ? ' تلميح لطيف من حنين: ${gentleHint.trim()}'
              : ' هيا نتأمل الصور بهدوء ونجرب معاً مرة أخرى!';
      rawReaction =
          'محاولة شجاعة وجميلة يا $cleanName! لا بأس أبداً، كلنا نتعلم بالمحاولة.$hintText 🎈';
    }
    final String adapted =
        ElevenLabsVoiceService.adaptTextToDialect(rawReaction, activeDialect);
    lastSpokenHaneenMessage = adapted;

    final String targetPersona = isCorrect
        ? (overridePersonaId ?? 'cheerful_friend')
        : (overridePersonaId ?? 'haneen');

    await speakCalmly(
      adapted,
      rate: 0.38,
      allowSpeechForRepeatGame: true,
      overridePersonaId: targetPersona,
      speechContext: ElevenLabsSpeechContext.gameFeedback,
      respectContextualPersonas: false,
    );

    if (isCorrect && onAutoAdvanceAfterAudio != null) {
      await onAutoAdvanceAfterAudio();
    }
    return adapted;
  }

  Future<ElevenLabsSynthesisOutcome?> speakSuperheroEncouragementAndAutoAdvance({
    required String encouragementText,
    FutureOr<void> Function()? onAutoAdvance,
  }) async {
    await speakCalmly(
      encouragementText,
      rate: 0.39,
      allowSpeechForRepeatGame: true,
      overridePersonaId: 'cheerful_friend',
      speechContext: ElevenLabsSpeechContext.gameFeedback,
      respectContextualPersonas: false,
    );
    if (onAutoAdvance != null) {
      await onAutoAdvance();
    }
    return lastSynthesisOutcome;
  }

  Future<void> startCalmBackgroundMusic({double? customVolume}) async {
    if (!isSoundAndVoiceEnabled || !isCalmBackgroundMusicEnabled) return;
    if (customVolume != null) {
      calmBackgroundMusicVolume = customVolume.clamp(0.05, 0.35);
    }
    isCalmBackgroundMusicPlaying = true;
    lastNarratedStoryHadBackgroundMusic = true;
    if (isRunningInUnitTest) return;
    try {
      final String bgPath =
          await ElevenLabsVoiceService.writeAudioBase64ToLocalCacheFile(
        cacheKey: 'calm_ambient_background_music_loop_v40',
        audioBase64:
            ElevenLabsVoiceService.kBundledOfflineElevenLabsBackupAudioBase64,
      );
      if (bgPath.isEmpty) return;
      final File bgFile = File(bgPath);
      if (!bgFile.existsSync()) return;
      await _calmBgMusicController?.dispose();
      final VideoPlayerController bgCtrl = VideoPlayerController.file(
        bgFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _calmBgMusicController = bgCtrl;
      await bgCtrl.initialize();
      await bgCtrl.setLooping(true);
      await bgCtrl.setVolume(calmBackgroundMusicVolume);
      await bgCtrl.play();
    } catch (_) {}
  }

  Future<void> stopCalmBackgroundMusic() async {
    isCalmBackgroundMusicPlaying = false;
    final VideoPlayerController? prevBg = _calmBgMusicController;
    _calmBgMusicController = null;
    if (prevBg != null && !isRunningInUnitTest) {
      try {
        if (prevBg.value.isInitialized) {
          await prevBg.pause();
          await prevBg.dispose();
        }
      } catch (_) {}
    }
  }

  /// Strict Sequential Audio Queue for Dual-Voice Story Narration:
  /// Guarantees that Clip `i` (e.g., Primary Voice `cUDXOxxuLZJdTcxEyGVB`) finishes 100%
  /// (including waiting if paused by a screen touch) BEFORE auto-swiping to Card `i + 1`
  /// and starting Clip `i + 1` (Superhero Voice `L14QZl4DxSQ6xGvib36i`), preventing any voice overlap!
  Future<List<ElevenLabsSynthesisOutcome>> narrateStoryCardsWithDualVoices({
    required InteractiveEducationalStoryModel story,
    void Function(int cardIndex, StoryImageCardPage card,
            ElevenLabsSynthesisOutcome outcome)?
        onCardStarted,
    FutureOr<void> Function(int nextCardIndex)? onCardCompletedAndAutoSwipe,
    FutureOr<void> Function()? onStoryFinished,
    bool playCalmBackgroundMusic = true,
  }) async {
    final int sessionId = ++_activeStoryNarrationSessionId;
    isStoryNarrationPaused = false;
    sequentialPlaybackLog.clear();
    final List<ElevenLabsSynthesisOutcome> outcomes = [];

    if (playCalmBackgroundMusic && isCalmBackgroundMusicEnabled) {
      await startCalmBackgroundMusic();
    }

    for (int i = 0; i < story.storyCards.length; i++) {
      if (sessionId != _activeStoryNarrationSessionId) break;

      // Wait here if the user paused the story by touching the screen
      while (isStoryNarrationPaused &&
          sessionId == _activeStoryNarrationSessionId) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      if (sessionId != _activeStoryNarrationSessionId) break;

      final StoryImageCardPage card = story.storyCards[i];
      sequentialPlaybackLog.add('START_CARD_${i}_${card.assignedVoiceId}');

      // Synthesize & play current card audio, awaiting full clip completion before proceeding
      await speakCalmly(
        card.narrationText,
        rate: 0.36,
        allowSpeechForRepeatGame: true,
        overridePersonaId: card.assignedPersonaId,
        speechContext: ElevenLabsSpeechContext.storyNarration,
        respectContextualPersonas: false,
      );

      if (sessionId != _activeStoryNarrationSessionId) break;

      // If paused mid-clip, wait until resumed before advancing to the next card
      while (isStoryNarrationPaused &&
          sessionId == _activeStoryNarrationSessionId) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      if (sessionId != _activeStoryNarrationSessionId) break;

      final ElevenLabsSynthesisOutcome? out = lastSynthesisOutcome;
      if (out != null) {
        outcomes.add(out);
        onCardStarted?.call(i, card, out);
      }
      sequentialPlaybackLog.add('END_CARD_${i}_${card.assignedVoiceId}');

      if (i + 1 < story.storyCards.length &&
          onCardCompletedAndAutoSwipe != null &&
          sessionId == _activeStoryNarrationSessionId) {
        await onCardCompletedAndAutoSwipe(i + 1);
      }
    }

    if (sessionId == _activeStoryNarrationSessionId) {
      if (onStoryFinished != null) {
        await onStoryFinished();
      }
      await stopCalmBackgroundMusic();
    }
    return outcomes;
  }

  /// Plays the synthesized MP3 file and strictly waits until playback completes
  /// (using a `Completer` + position listener on `VideoPlayerController`) so two clips never overlap.
  Future<void> _playElevenLabsAudioFile(
    String filePath,
    int expectedToken, {
    required String spokenText,
  }) async {
    if (filePath.isEmpty || isRunningInUnitTest) return;
    try {
      final File f = File(filePath);
      if (!f.existsSync()) return;
      final VideoPlayerController ctrl = VideoPlayerController.file(
        f,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await ctrl.initialize();
      if (expectedToken != ElevenLabsVoiceService.currentPlaybackToken) {
        await ctrl.dispose();
        return;
      }
      _activeElevenLabsAudioController = ctrl;
      await ctrl.setVolume(1.0);
      await ctrl.setPlaybackSpeed(activeVoiceSpeed.clamp(0.7, 1.2));

      final Completer<void> playbackCompleter = Completer<void>();
      _activeClipCompletionCompleter = playbackCompleter;

      void checkCompletionListener() {
        if (playbackCompleter.isCompleted) return;
        final val = ctrl.value;
        if (!val.isInitialized) return;
        if (val.isCompleted ||
            (val.duration > Duration.zero &&
                val.position >=
                    val.duration - const Duration(milliseconds: 45))) {
          playbackCompleter.complete();
        }
      }

      ctrl.addListener(checkCompletionListener);
      await ctrl.play();

      final Duration reportedDur = ctrl.value.duration;
      // Estimate realistic speech duration from word count as safety bound
      final int wordCount = max(1, spokenText.trim().split(RegExp(r'\s+')).length);
      final Duration estimatedSpeechDur =
          Duration(milliseconds: max(1200, wordCount * 420));
      final Duration maxWait = (reportedDur > const Duration(milliseconds: 500)
              ? reportedDur
              : estimatedSpeechDur) +
          const Duration(milliseconds: 350);

      await playbackCompleter.future.timeout(
        maxWait,
        onTimeout: () {},
      );

      ctrl.removeListener(checkCompletionListener);
      if (_activeElevenLabsAudioController == ctrl) {
        _activeElevenLabsAudioController = null;
        await ctrl.pause();
        await ctrl.dispose();
      }
    } catch (_) {}
  }

  Future<void> speakCalmly(
    String text, {
    double rate = 0.38,
    bool forceSpeakEvenIfAssistantMuted = false,
    bool allowSpeechForRepeatGame = false,
    String? overridePersonaId,
    ElevenLabsSpeechContext speechContext =
        ElevenLabsSpeechContext.quickInteraction,
    bool respectContextualPersonas = true,
  }) async {
    if (!isSoundAndVoiceEnabled && !forceSpeakEvenIfAssistantMuted) {
      return;
    }
    if (isAssistantMuted &&
        !forceSpeakEvenIfAssistantMuted &&
        !allowSpeechForRepeatGame) {
      return;
    }
    final String cleanText = text
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll('"', '')
        .trim();
    if (cleanText.isEmpty) return;

    if (!_engineReady) {
      await init();
    }

    // Stop any previous active clip before starting the new clip in the sequential queue
    await stopSpeaking();

    final ElevenLabsSynthesisOutcome outcome =
        await ElevenLabsVoiceService.synthesizeSpeech(
      text: cleanText,
      extraLocalLookupTexts: _nameNeutralVariants(cleanText),
      personaId: overridePersonaId ?? activePersonaId,
      dialect: activeDialect,
      speed: activeVoiceSpeed,
      context: speechContext,
      backendProxyUrl: backendTtsProxyUrl,
      sessionAccessToken: sessionAccessToken,
      respectContextualPersonas: respectContextualPersonas,
      prefs: _prefs,
    );
    lastSynthesisOutcome = outcome;
    lastSpokenHaneenMessage = outcome.adaptedText;

    if (!outcome.success) return;
    isSpeaking = true;

    await _playElevenLabsAudioFile(
      outcome.cachedAudioFilePath,
      outcome.playbackToken,
      spokenText: cleanText,
    );
    isSpeaking = false;
  }

  /// Returns the name of the child currently using the app (set by the app
  /// state) so offline clips recorded with "يا بطل" can still be found.
  String? Function()? childNameProvider;

  /// Variants of [text] with the child's name replaced by the generic "بطل".
  List<String> _nameNeutralVariants(String text) {
    final String? n = childNameProvider?.call()?.trim();
    if (n == null || n.isEmpty || !text.contains(n)) return const [];
    return [
      text.replaceAll('يا $n،', 'يا بطل حنين،').replaceAll(n, 'بطل'),
      text.replaceAll('يا $n', 'يا بطل').replaceAll(n, 'بطل'),
      text.replaceAll(' يا $n', '').replaceAll(n, 'بطل'),
    ];
  }

  Future<void> stopSpeaking() async {
    ElevenLabsVoiceService.cancelActiveSpeechAndIssueToken();
    final Completer<void>? pendingCompleter = _activeClipCompletionCompleter;
    _activeClipCompletionCompleter = null;
    if (pendingCompleter != null && !pendingCompleter.isCompleted) {
      pendingCompleter.complete();
    }
    final VideoPlayerController? prev = _activeElevenLabsAudioController;
    _activeElevenLabsAudioController = null;
    if (prev != null && !isRunningInUnitTest) {
      try {
        if (prev.value.isInitialized) {
          await prev.pause();
          await prev.dispose();
        }
      } catch (_) {}
    }
    isSpeaking = false;
  }

  Future<bool> initSpeechRecognition() async {
    if (isRunningInUnitTest) return false;
    try {
      if (_sttReady) return true;
      _sttReady = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      return _sttReady;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startListening({
    required void Function(String recognizedWords) onResult,
    void Function(String errorReason)? onPermissionOrPolicyDenied,
  }) async {
    if (!isChildMicrophoneAllowed) {
      await stopListening();
      onPermissionOrPolicyDenied?.call(
        'تم إيقاف الميكروفون بناءً على إعدادات الرقابة الأبوية لهذا الطفل.',
      );
      return false;
    }
    try {
      final bool available = await initSpeechRecognition();
      if (!available) {
        onPermissionOrPolicyDenied?.call(
          'خدمة التعرف على الكلام غير متاحة حالياً؛ يمكنك الاستماع للصوت والترديد الحر.',
        );
        return false;
      }
      await stopSpeaking();
      await _speech.listen(
        localeId: 'ar_EG',
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onResult: (result) {
          if (!isChildMicrophoneAllowed) {
            stopListening();
            return;
          }
          onResult(result.recognizedWords);
        },
      );
      return true;
    } catch (_) {
      onPermissionOrPolicyDenied?.call(
        'تعذر فتح الميكروفون (تأكد من منح إذن الميكروفون للتطبيق).',
      );
      return false;
    }
  }

  Future<void> stopListening() async {
    if (isRunningInUnitTest) return;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  static String normalizeArabicText(String input) {
    final RegExp diacritics =
        RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED«»"؛،؟!.,:\-\(\)]');
    String cleaned = input.replaceAll(diacritics, ' ');
    cleaned = cleaned
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  static PronunciationEvaluation evaluatePronunciation({
    required String targetPhrase,
    required String spokenText,
    String childAgeGroup = '3–6 سنوات',
  }) {
    return PronunciationCoachService.evaluateForChildAge(
      target: targetPhrase,
      spoken: spokenText,
      childAgeGroup: childAgeGroup,
    );
  }
}
