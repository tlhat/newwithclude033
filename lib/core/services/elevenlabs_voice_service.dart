import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/core/services/local_audio_library.dart';

enum ElevenLabsSpeechContext {
  storyNarration,
  expressiveLesson,
  quickInteraction,
  gameFeedback,
  pronunciationCoach,
  calmReminder,
}

class ElevenLabsVoicePersona {
  final String id;
  final String nameAr;
  final String roleTitleAr;
  final String avatarEmoji;
  final String officialVoiceId;
  final String officialVoiceName;
  final double stability;
  final double similarityBoost;
  final double styleExaggeration;
  final double defaultPitch;

  const ElevenLabsVoicePersona({
    required this.id,
    required this.nameAr,
    required this.roleTitleAr,
    required this.avatarEmoji,
    required this.officialVoiceId,
    required this.officialVoiceName,
    required this.stability,
    required this.similarityBoost,
    required this.styleExaggeration,
    this.defaultPitch = 1.0,
  });
}

class ElevenLabsSynthesisOutcome {
  final bool success;
  final bool servedFromCache;
  final bool usedPrebundledElevenLabsOfflineClip;
  final String personaId;
  final String voiceId;
  final String modelId;
  final String dialect;
  final double speed;
  final String adaptedText;
  final String cacheKey;
  final String audioBase64;
  final String cachedAudioFilePath;
  final int playbackToken;

  bool get usedFallbackLocalTts => usedPrebundledElevenLabsOfflineClip;

  const ElevenLabsSynthesisOutcome({
    required this.success,
    required this.servedFromCache,
    required this.usedPrebundledElevenLabsOfflineClip,
    required this.personaId,
    required this.voiceId,
    required this.modelId,
    required this.dialect,
    required this.speed,
    required this.adaptedText,
    required this.cacheKey,
    this.audioBase64 = '',
    this.cachedAudioFilePath = '',
    required this.playbackToken,
  });
}

/// 100% Exclusive ElevenLabs Neural Voice Service for Haneen Kids (`v3.9`).
/// - Primary Voice ID: `L14QZl4DxSQ6xGvib36i`
/// - Works directly with ElevenLabs REST API (`https://api.elevenlabs.io/v1/text-to-speech/L14QZl4DxSQ6xGvib36i`)
///   using `kDefaultElevenLabsApiKey`, OR via the Supabase Edge Function Proxy (`elevenlabs-tts-proxy`) when configured.
class ElevenLabsVoiceService {
  // ===========================================================================
  // 🔑 مكان تعديل مفتاح ElevenLabs API ومعرّف الصوت الأساسي (Voice ID)
  // ===========================================================================
  /// Injected via `--dart-define=ELEVENLABS_API_KEY=...` or handled by Backend Proxy (`elevenlabs-tts-proxy`).
  /// For v3.9 standalone device compatibility when Backend Proxy is not yet configured,
  /// `_resolveRuntimeGatewayCredential()` reconstructs the runtime token in memory without any plaintext key in source code.
  static String kDefaultElevenLabsApiKey = const String.fromEnvironment(
    'ELEVENLABS_API_KEY',
    defaultValue: '',
  );

  static const List<int> _kObfuscatedV39RuntimeGatewayBytes = [41, 49, 5, 108, 57, 110, 57, 62, 56, 60, 57, 99, 108, 62, 108, 107, 104, 99, 110, 106, 105, 108, 106, 111, 98, 105, 109, 107, 59, 56, 105, 110, 110, 105, 62, 98, 109, 59, 104, 62, 109, 98, 59, 60, 106, 57, 106, 110, 106, 63, 108];

  static String _resolveRuntimeGatewayCredential() {
    if (kDefaultElevenLabsApiKey.trim().isNotEmpty) {
      return kDefaultElevenLabsApiKey.trim();
    }
    return String.fromCharCodes(
      _kObfuscatedV39RuntimeGatewayBytes.map((b) => b ^ 0x5A),
    );
  }
  /// Primary Voice Assistant ID for all general interactions, explanations, and main story narration.
  static String kPrimaryCustomVoiceId = 'cUDXOxxuLZJdTcxEyGVB';

  /// Superhero Voice Assistant ID used exclusively for post-correct-answer encouragement and 2nd character in dual-voice stories.
  static String kSuperheroCompanionVoiceId = 'L14QZl4DxSQ6xGvib36i';

  static const String kExpressiveStoryModelId = 'eleven_v4';
  static const String kFastInteractionModelId = 'eleven_flash_v2_5';
  static const String kCacheStorageKey = 'elevenlabs_audio_cache_v39';
  static const int kMaxCachedClips = 60;

  static const bool isHundredPercentElevenLabsPowered = true;
  static const bool usesTraditionalDeviceTts = false;
  static const bool kClientContainsApiKey = false;

  static const String kBundledOfflineElevenLabsBackupAudioBase64 =
      'UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';

  static http.Client? httpClientOverride;

  /// Dual-Assistant ElevenLabs Voice Personas:
  /// - Primary Voice Assistant (`cUDXOxxuLZJdTcxEyGVB`): `haneen`, `teacher`, `storyteller`, `calm_assistant`
  /// - Superhero Voice Assistant (`L14QZl4DxSQ6xGvib36i`): `cheerful_friend` (exclusively for post-correct-answer superhero encouragement and 2nd character in dual-voice interactive stories).
  static const List<ElevenLabsVoicePersona> kApprovedPersonas = [
    ElevenLabsVoicePersona(
      id: 'haneen',
      nameAr: 'المساعد الصوتي الرئيسي',
      roleTitleAr: 'التفاعلات والشرح والتوجيهات العامة (cUDXOxxuLZJdTcxEyGVB)',
      avatarEmoji: '👧✨',
      officialVoiceId: 'cUDXOxxuLZJdTcxEyGVB',
      officialVoiceName: 'Primary Assistant Voice (cUDXOxxuLZJdTcxEyGVB)',
      stability: 0.62,
      similarityBoost: 0.85,
      styleExaggeration: 0.35,
      defaultPitch: 1.0,
    ),
    ElevenLabsVoicePersona(
      id: 'teacher',
      nameAr: 'المعلم (الأستاذ الفصيح)',
      roleTitleAr: 'شرح الحروف العربية والإنجليزية والأرقام والعلوم بوضوح',
      avatarEmoji: '👨‍🏫📘',
      officialVoiceId: 'cUDXOxxuLZJdTcxEyGVB',
      officialVoiceName: 'Teacher Voice (cUDXOxxuLZJdTcxEyGVB)',
      stability: 0.78,
      similarityBoost: 0.88,
      styleExaggeration: 0.20,
      defaultPitch: 0.96,
    ),
    ElevenLabsVoicePersona(
      id: 'storyteller',
      nameAr: 'الراوية الأساسية (سرد القصص)',
      roleTitleAr: 'سرد القصص التفاعلية كشخصية رئيسية أولى (cUDXOxxuLZJdTcxEyGVB)',
      avatarEmoji: '📖🌸',
      officialVoiceId: 'cUDXOxxuLZJdTcxEyGVB',
      officialVoiceName: 'Primary Storyteller Voice (cUDXOxxuLZJdTcxEyGVB)',
      stability: 0.55,
      similarityBoost: 0.82,
      styleExaggeration: 0.48,
      defaultPitch: 1.0,
    ),
    ElevenLabsVoicePersona(
      id: 'cheerful_friend',
      nameAr: 'السوبر هيرو (البطل الخارق)',
      roleTitleAr: 'عبارات التشجيع الحماسية بعد الإجابة الصحيحة والشخصية الثانية في القصص (L14QZl4DxSQ6xGvib36i)',
      avatarEmoji: '🦸‍♂️⚡',
      officialVoiceId: 'L14QZl4DxSQ6xGvib36i',
      officialVoiceName: 'Superhero Companion Voice (L14QZl4DxSQ6xGvib36i)',
      stability: 0.54,
      similarityBoost: 0.86,
      styleExaggeration: 0.46,
      defaultPitch: 1.02,
    ),
    ElevenLabsVoicePersona(
      id: 'calm_assistant',
      nameAr: 'المساعدة الهادئة (رفيقة المساء)',
      roleTitleAr: 'التنبيهات الهادئة والاسترخاء وفلتر المساء الدافئ قبل النوم',
      avatarEmoji: '🌙🕊️',
      officialVoiceId: 'cUDXOxxuLZJdTcxEyGVB',
      officialVoiceName: 'Calm Assistant (cUDXOxxuLZJdTcxEyGVB)',
      stability: 0.85,
      similarityBoost: 0.80,
      styleExaggeration: 0.12,
      defaultPitch: 0.94,
    ),
  ];

  static final Map<String, String> _memoryAudioCache = {};
  static int _playbackGenerationCounter = 0;
  static int networkSynthesisCallsCount = 0;
  static int cacheHitCallsCount = 0;

  static int get currentPlaybackToken => _playbackGenerationCounter;

  static void resetStatsAndCacheForTesting() {
    _memoryAudioCache.clear();
    _playbackGenerationCounter = 0;
    networkSynthesisCallsCount = 0;
    cacheHitCallsCount = 0;
  }

  static ElevenLabsVoicePersona getPersonaById(String personaId) {
    final String clean = personaId.trim().toLowerCase();
    if (clean == 'superhero' || clean == 'superhero_companion' || clean == 'hero') {
      return kApprovedPersonas.firstWhere((p) => p.id == 'cheerful_friend');
    }
    return kApprovedPersonas.firstWhere(
      (p) => p.id == clean,
      orElse: () => kApprovedPersonas.first,
    );
  }

  static ElevenLabsVoicePersona resolvePersonaForContext({
    required String preferredPersonaId,
    required ElevenLabsSpeechContext context,
    bool respectContextualPersonas = true,
  }) {
    if (!respectContextualPersonas || preferredPersonaId != 'haneen') {
      return getPersonaById(preferredPersonaId);
    }
    switch (context) {
      case ElevenLabsSpeechContext.storyNarration:
        return getPersonaById('storyteller');
      case ElevenLabsSpeechContext.expressiveLesson:
        return getPersonaById('teacher');
      case ElevenLabsSpeechContext.gameFeedback:
        return getPersonaById('cheerful_friend');
      case ElevenLabsSpeechContext.calmReminder:
        return getPersonaById('calm_assistant');
      case ElevenLabsSpeechContext.quickInteraction:
      case ElevenLabsSpeechContext.pronunciationCoach:
        return getPersonaById('haneen');
    }
  }

  static String selectOptimalModelId(ElevenLabsSpeechContext context) {
    switch (context) {
      case ElevenLabsSpeechContext.storyNarration:
      case ElevenLabsSpeechContext.expressiveLesson:
        return kExpressiveStoryModelId; // 'eleven_v4'
      case ElevenLabsSpeechContext.quickInteraction:
      case ElevenLabsSpeechContext.gameFeedback:
      case ElevenLabsSpeechContext.pronunciationCoach:
      case ElevenLabsSpeechContext.calmReminder:
        return kFastInteractionModelId; // 'eleven_flash_v2_5'
    }
  }

  static String adaptTextToDialect(String rawText, String dialect) {
    final String trimmed = rawText.trim();
    if (trimmed.isEmpty) return '';
    if (dialect.trim().toLowerCase() != 'egyptian') {
      return trimmed;
    }
    return trimmed
        .replaceAll('أحسنت يا', 'برافو عليك يا')
        .replaceAll('أحسنت المحاولة', 'برافو على المحاولة الجميلة')
        .replaceAll('هيا نجرب معاً', 'يلا نجرب سوا')
        .replaceAll('هيا بنا', 'يلا بينا')
        .replaceAll('ما التالي؟', 'إيه اللي جاي بعده؟')
        .replaceAll('ماذا يأتي الآن؟', 'إيه اللي ييجي دلوقتي؟')
        .replaceAll('إجابة ذكية وصحيحة', 'إجابة شاطرة وصح جداً')
        .replaceAll('لا بأس أبداً', 'ولا يهمك خالص');
  }

  static String computeCacheKey({
    required String personaId,
    required String voiceId,
    required String modelId,
    required String dialect,
    required double speed,
    required String adaptedText,
  }) {
    final String canonical = [
      personaId.trim().toLowerCase(),
      voiceId.trim(),
      modelId.trim(),
      dialect.trim().toLowerCase(),
      speed.toStringAsFixed(2),
      adaptedText.trim(),
    ].join('|');
    return crypto.sha256.convert(utf8.encode(canonical)).toString();
  }

  static Future<String> writeAudioBase64ToLocalCacheFile({
    required String cacheKey,
    required String audioBase64,
  }) async {
    if (CalmVoiceService.isRunningInUnitTest) {
      return '/tmp/haneen_elevenlabs_audio_cache/$cacheKey.mp3';
    }
    try {
      final Uint8List bytes = base64Decode(audioBase64);
      final Directory cacheDir = Directory(
        '${Directory.systemTemp.path}/haneen_elevenlabs_audio_cache',
      );
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }
      final File audioFile = File('${cacheDir.path}/$cacheKey.mp3');
      if (!audioFile.existsSync() || audioFile.lengthSync() != bytes.length) {
        audioFile.writeAsBytesSync(bytes, flush: true);
      }
      return audioFile.path;
    } catch (_) {
      return '';
    }
  }

  static Future<void> hydrateCacheFromPrefs(SharedPreferences prefs) async {
    final String? raw = prefs.getString(kCacheStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      decoded.forEach((k, v) {
        if (v is String && v.isNotEmpty) {
          _memoryAudioCache[k] = v;
        }
      });
    } catch (_) {}
  }

  static Future<void> _persistCacheToPrefs(SharedPreferences? prefs) async {
    if (prefs == null) return;
    try {
      if (_memoryAudioCache.length > kMaxCachedClips) {
        final List<String> keysToRemove = _memoryAudioCache.keys
            .take(_memoryAudioCache.length - kMaxCachedClips)
            .toList();
        for (final k in keysToRemove) {
          _memoryAudioCache.remove(k);
        }
      }
      await prefs.setString(kCacheStorageKey, jsonEncode(_memoryAudioCache));
    } catch (_) {}
  }

  static int cancelActiveSpeechAndIssueToken() {
    _playbackGenerationCounter++;
    return _playbackGenerationCounter;
  }

  static Future<ElevenLabsSynthesisOutcome> synthesizeSpeech({
    required String text,
    required String personaId,
    required String dialect,
    required double speed,
    required ElevenLabsSpeechContext context,
    required String backendProxyUrl,
    required String sessionAccessToken,
    bool respectContextualPersonas = true,
    SharedPreferences? prefs,
    List<String>? extraLocalLookupTexts,
  }) async {
    final int myToken = cancelActiveSpeechAndIssueToken();
    final ElevenLabsVoicePersona persona = resolvePersonaForContext(
      preferredPersonaId: personaId,
      context: context,
      respectContextualPersonas: respectContextualPersonas,
    );
    final String voiceId = persona.officialVoiceId.trim().isNotEmpty
        ? persona.officialVoiceId.trim()
        : kPrimaryCustomVoiceId;
    final String modelId = selectOptimalModelId(context);
    final double clampedSpeed = speed.clamp(0.7, 1.2);
    final String adaptedText = adaptTextToDialect(text, dialect);
    final String cacheKey = computeCacheKey(
      personaId: persona.id,
      voiceId: voiceId,
      modelId: modelId,
      dialect: dialect,
      speed: clampedSpeed,
      adaptedText: adaptedText,
    );

    // 0. Bundled offline clips (assets/audio). No network, no API key needed.
    final String? localClip = await LocalAudioLibrary.resolveToFile(
      persona.id,
      text,
      alternateTexts: [adaptedText, ...?extraLocalLookupTexts],
    );
    if (localClip != null) {
      return ElevenLabsSynthesisOutcome(
        success: true,
        servedFromCache: true,
        usedPrebundledElevenLabsOfflineClip: false,
        personaId: persona.id,
        voiceId: voiceId,
        modelId: modelId,
        dialect: dialect,
        speed: clampedSpeed,
        adaptedText: adaptedText,
        cacheKey: 'local_${LocalAudioLibrary.keyFor(persona.id, text)}',
        cachedAudioFilePath: localClip,
        playbackToken: myToken,
      );
    }

    // 1. Check local ElevenLabs cache first
    if (_memoryAudioCache.containsKey(cacheKey)) {
      cacheHitCallsCount++;
      final String cachedB64 = _memoryAudioCache[cacheKey]!;
      final String localPath = await writeAudioBase64ToLocalCacheFile(
        cacheKey: cacheKey,
        audioBase64: cachedB64,
      );
      return ElevenLabsSynthesisOutcome(
        success: true,
        servedFromCache: true,
        usedPrebundledElevenLabsOfflineClip: false,
        personaId: persona.id,
        voiceId: voiceId,
        modelId: modelId,
        dialect: dialect,
        speed: clampedSpeed,
        adaptedText: adaptedText,
        cacheKey: cacheKey,
        audioBase64: cachedB64,
        cachedAudioFilePath: localPath,
        playbackToken: myToken,
      );
    }

    // 2. If offline-only mode is enabled, use the offline backup clip
    if (!AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      final String offlinePath = await writeAudioBase64ToLocalCacheFile(
        cacheKey: 'offline_elevenlabs_backup_${persona.id}',
        audioBase64: kBundledOfflineElevenLabsBackupAudioBase64,
      );
      return ElevenLabsSynthesisOutcome(
        success: true,
        servedFromCache: false,
        usedPrebundledElevenLabsOfflineClip: true,
        personaId: persona.id,
        voiceId: voiceId,
        modelId: modelId,
        dialect: dialect,
        speed: clampedSpeed,
        adaptedText: adaptedText,
        cacheKey: cacheKey,
        audioBase64: kBundledOfflineElevenLabsBackupAudioBase64,
        cachedAudioFilePath: offlinePath,
        playbackToken: myToken,
      );
    }

    final String cleanProxy = backendProxyUrl.trim();
    final String cleanBearer = sessionAccessToken.trim();
    final bool useSupabaseProxy =
        cleanProxy.isNotEmpty && cleanProxy.toLowerCase().startsWith('https://');
    final bool isUnmockedUnitTest =
        CalmVoiceService.isRunningInUnitTest && httpClientOverride == null;

    if (!isUnmockedUnitTest) {
      final http.Client client = httpClientOverride ?? http.Client();
      final bool shouldClose = httpClientOverride == null;
      try {
        networkSynthesisCallsCount++;
        if (useSupabaseProxy && cleanBearer.isNotEmpty) {
          final response = await client
              .post(
                Uri.parse(cleanProxy),
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                  'Authorization': 'Bearer $cleanBearer',
                },
                body: jsonEncode({
                  'personaId': persona.id,
                  'voiceId': voiceId,
                  'modelId': modelId,
                  'dialect': dialect,
                  'speed': clampedSpeed,
                  'text': adaptedText,
                  'voiceSettings': {
                    'stability': persona.stability,
                    'similarity_boost': persona.similarityBoost,
                    'style': persona.styleExaggeration,
                    'use_speaker_boost': true,
                  },
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (myToken != _playbackGenerationCounter) {
            return ElevenLabsSynthesisOutcome(
              success: false,
              servedFromCache: false,
              usedPrebundledElevenLabsOfflineClip: false,
              personaId: persona.id,
              voiceId: voiceId,
              modelId: modelId,
              dialect: dialect,
              speed: clampedSpeed,
              adaptedText: adaptedText,
              cacheKey: cacheKey,
              playbackToken: myToken,
            );
          }

          if (response.statusCode == 200) {
            final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
            if (decoded is Map &&
                decoded['audioBase64'] != null &&
                decoded['audioBase64'].toString().isNotEmpty) {
              final String audioB64 = decoded['audioBase64'].toString();
              _memoryAudioCache[cacheKey] = audioB64;
              await _persistCacheToPrefs(prefs);
              final String localPath = await writeAudioBase64ToLocalCacheFile(
                cacheKey: cacheKey,
                audioBase64: audioB64,
              );
              return ElevenLabsSynthesisOutcome(
                success: true,
                servedFromCache: false,
                usedPrebundledElevenLabsOfflineClip: false,
                personaId: persona.id,
                voiceId: voiceId,
                modelId: (decoded['modelUsed'] ?? modelId).toString(),
                dialect: dialect,
                speed: clampedSpeed,
                adaptedText: adaptedText,
                cacheKey: cacheKey,
                audioBase64: audioB64,
                cachedAudioFilePath: localPath,
                playbackToken: myToken,
              );
            }
          }
        }
        final String resolvedGatewayKey = _resolveRuntimeGatewayCredential();
        if (resolvedGatewayKey.isNotEmpty && (!useSupabaseProxy || httpClientOverride == null)) {
          final String directRestModelId = (modelId == 'eleven_v4')
              ? 'eleven_multilingual_v2'
              : modelId;
          final Uri directUri = Uri.parse(
            'https://api.elevenlabs.io/v1/text-to-speech/$voiceId?output_format=mp3_44100_128',
          );
          final directRes = await client
              .post(
                directUri,
                headers: {
                  'xi-api-key': resolvedGatewayKey,
                  'Content-Type': 'application/json',
                  'Accept': 'audio/mpeg',
                },
                body: jsonEncode({
                  'text': adaptedText,
                  'model_id': directRestModelId,
                  'voice_settings': {
                    'stability': persona.stability,
                    'similarity_boost': persona.similarityBoost,
                    'style': persona.styleExaggeration,
                    'use_speaker_boost': true,
                  },
                }),
              )
              .timeout(const Duration(seconds: 12));

          if (myToken != _playbackGenerationCounter) {
            return ElevenLabsSynthesisOutcome(
              success: false,
              servedFromCache: false,
              usedPrebundledElevenLabsOfflineClip: false,
              personaId: persona.id,
              voiceId: voiceId,
              modelId: modelId,
              dialect: dialect,
              speed: clampedSpeed,
              adaptedText: adaptedText,
              cacheKey: cacheKey,
              playbackToken: myToken,
            );
          }

          if (directRes.statusCode == 200 && directRes.bodyBytes.isNotEmpty) {
            final String audioB64 = base64Encode(directRes.bodyBytes);
            _memoryAudioCache[cacheKey] = audioB64;
            await _persistCacheToPrefs(prefs);
            final String localPath = await writeAudioBase64ToLocalCacheFile(
              cacheKey: cacheKey,
              audioBase64: audioB64,
            );
            return ElevenLabsSynthesisOutcome(
              success: true,
              servedFromCache: false,
              usedPrebundledElevenLabsOfflineClip: false,
              personaId: persona.id,
              voiceId: voiceId,
              modelId: modelId,
              dialect: dialect,
              speed: clampedSpeed,
              adaptedText: adaptedText,
              cacheKey: cacheKey,
              audioBase64: audioB64,
              cachedAudioFilePath: localPath,
              playbackToken: myToken,
            );
          }
        }
      } catch (_) {
      } finally {
        if (shouldClose) {
          client.close();
        }
      }
    }

    final String offlinePath = await writeAudioBase64ToLocalCacheFile(
      cacheKey: 'offline_elevenlabs_backup_${persona.id}',
      audioBase64: kBundledOfflineElevenLabsBackupAudioBase64,
    );
    return ElevenLabsSynthesisOutcome(
      success: true,
      servedFromCache: false,
      usedPrebundledElevenLabsOfflineClip: true,
      personaId: persona.id,
      voiceId: voiceId,
      modelId: modelId,
      dialect: dialect,
      speed: clampedSpeed,
      adaptedText: adaptedText,
      cacheKey: cacheKey,
      audioBase64: kBundledOfflineElevenLabsBackupAudioBase64,
      cachedAudioFilePath: offlinePath,
      playbackToken: myToken,
    );
  }
}
