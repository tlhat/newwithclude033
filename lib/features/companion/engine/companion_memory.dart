import 'dart:convert';

import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 5: lightweight, local-first persistent companion memory, strictly
/// isolated per childId. Stores only the minimum context needed for
/// contextual greetings and learning continuity:
/// child name, preferred companion (boy/girl), last completed activity,
/// valid unfinished session, recent achievements, weak concepts (Phase 4),
/// last interaction context, and the last presented greeting id.
class CompanionMemorySnapshot {
  final String childId;
  final String childName;
  final String preferredCompanion; // 'boy' | 'girl'
  final String? lastCompletedActivityId;
  final String? unfinishedLessonId;
  final String? unfinishedSessionStartedAtIso;
  final List<String> recentAchievements; // capped, no duplicates
  final List<String> weakLessonIds; // from LessonProgressBridge
  final String? lastInteractionContext;
  final String? lastGreetingId;
  final String updatedAtIso;

  CompanionMemorySnapshot({
    required this.childId,
    required this.childName,
    required this.preferredCompanion,
    this.lastCompletedActivityId,
    this.unfinishedLessonId,
    this.unfinishedSessionStartedAtIso,
    List<String>? recentAchievements,
    List<String>? weakLessonIds,
    this.lastInteractionContext,
    this.lastGreetingId,
    String? updatedAtIso,
  })  : recentAchievements = _dedup(recentAchievements ?? const []).take(5).toList(),
        weakLessonIds = _dedup(weakLessonIds ?? const []),
        updatedAtIso = updatedAtIso ?? DateTime.now().toIso8601String();

  static List<String> _dedup(List<String> list) => <String>{...list}.toList();

  bool get isFresh => DateTime.tryParse(updatedAtIso) != null;

  /// Unfinished session is only resumable while the lesson is not completed.
  bool hasResumableSession(Set<String> completedLessonIds) {
    final String? lessonId = unfinishedLessonId;
    if (lessonId == null || lessonId.trim().isEmpty) return false;
    if (unfinishedSessionStartedAtIso == null) return false;
    final DateTime? started = DateTime.tryParse(unfinishedSessionStartedAtIso ?? '');
    if (started == null) return false;
    // Sessions older than 7 days are considered stale, never "completed".
    if (DateTime.now().difference(started) > const Duration(days: 7)) {
      return false;
    }
    return !completedLessonIds.contains(lessonId);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'childId': childId,
        'childName': childName,
        'preferredCompanion': preferredCompanion,
        'lastCompletedActivityId': lastCompletedActivityId,
        'unfinishedLessonId': unfinishedLessonId,
        'unfinishedSessionStartedAt': unfinishedSessionStartedAtIso,
        'recentAchievements': recentAchievements,
        'weakLessonIds': weakLessonIds,
        'lastInteractionContext': lastInteractionContext,
        'lastGreetingId': lastGreetingId,
        'updatedAt': updatedAtIso,
      };

  static CompanionMemorySnapshot? tryParse(String rawJson) {
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map) return null;
      final String? childId = decoded['childId']?.toString();
      if (childId == null || childId.isEmpty) return null;
      return CompanionMemorySnapshot(
        childId: childId,
        childName: decoded['childName']?.toString() ?? '',
        preferredCompanion:
            decoded['preferredCompanion']?.toString() == 'girl' ? 'girl' : 'boy',
        lastCompletedActivityId: _nullableString(decoded['lastCompletedActivityId']),
        unfinishedLessonId: _nullableString(decoded['unfinishedLessonId']),
        unfinishedSessionStartedAtIso:
            _nullableString(decoded['unfinishedSessionStartedAt']),
        recentAchievements: _stringList(decoded['recentAchievements']),
        weakLessonIds: _stringList(decoded['weakLessonIds']),
        lastInteractionContext: _nullableString(decoded['lastInteractionContext']),
        lastGreetingId: _nullableString(decoded['lastGreetingId']),
        updatedAtIso: _nullableString(decoded['updatedAt']),
      );
    } catch (_) {
      return null; // graceful fallback on corrupted data
    }
  }

  static String? _nullableString(Object? v) =>
      v == null ? null : v.toString();
  static List<String>? _stringList(Object? v) {
    if (v is! List) return null;
    return v.map((e) => e.toString()).toList();
  }
}

/// Result of building a contextual greeting. `speakAllowed` is false when
/// mute / TTS-off / parental lock / active playback forbids speaking;
/// the text is still safe to display silently.
class CompanionGreeting {
  final String id;
  final String text;
  final bool speakAllowed;
  const CompanionGreeting(this.id, this.text, this.speakAllowed);
}

class CompanionMemoryEngine {
  static const String _keyPrefix = 'companion_memory_v1_';

  static String keyFor(String childId) => '$_keyPrefix$childId';

  /// Loads the snapshot for [childId]; returns null when missing or corrupted
  /// (callers fall back to a fresh snapshot derived from the ChildProfile).
  static CompanionMemorySnapshot? loadFrom(SharedPreferences prefs, String childId) {
    final String? raw = prefs.getString(keyFor(childId));
    if (raw == null) return null;
    return CompanionMemorySnapshot.tryParse(raw);
  }

  /// Serializes and persists the snapshot (whole-key replacement => no
  /// duplicate records). Safe on failure (returns false).
  static Future<bool> saveTo(SharedPreferences prefs, CompanionMemorySnapshot snapshot) async {
    try {
      final bool ok = await prefs.setString(
        keyFor(snapshot.childId),
        jsonEncode(snapshot.toJson()),
      );
      return ok;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> clearFor(SharedPreferences prefs, String childId) async {
    try {
      return await prefs.remove(keyFor(childId));
    } catch (_) {
      return false;
    }
  }

  /// Builds a fresh snapshot from the live ChildProfile, reusing Phase 4
  /// (LessonProgressBridge weak-concept detection).
  static CompanionMemorySnapshot syncFromChild(ChildProfile child) {
    final LessonProgressBridgeResult bridge =
        LessonProgressBridge.analyze(child: child);
    return CompanionMemorySnapshot(
      childId: child.id,
      childName: child.name,
      preferredCompanion: child.gender == 'girl' ? 'girl' : 'boy',
      lastCompletedActivityId:
          child.completedLessons.isEmpty ? null : child.completedLessons.last,
      unfinishedLessonId: child.completedLessons
              .contains(child.lastActiveAcademyLessonId)
          ? null
          : child.lastActiveAcademyLessonId,
      unfinishedSessionStartedAtIso: DateTime.now().toIso8601String(),
      weakLessonIds: bridge.weakLessonIds,
      lastInteractionContext: 'feed',
    );
  }

  /// Contextual, non-repeating greeting. Deterministic rotation of a fixed
  /// template pool per locale; never immediately repeats the last presented
  /// greeting; never claims the child completed something they did not
  /// (achievements only come from real ledger/profile data).
  static CompanionGreeting buildGreeting(
    CompanionMemorySnapshot snapshot, {
    String locale = 'ar',
    bool isMuted = false,
    bool ttsEnabled = true,
    bool parentalLocked = false,
    bool isSpeaking = false,
    bool lessonActive = false,
  }) {
    final bool speakAllowed = !isMuted &&
        ttsEnabled &&
        !parentalLocked &&
        !isSpeaking &&
        !lessonActive;
    const List<String> idsAr = <String>['g_ar_1', 'g_ar_2', 'g_ar_3', 'g_ar_4'];
    const List<String> idsEn = <String>['g_en_1', 'g_en_2', 'g_en_3', 'g_en_4'];
    final List<String> ids = locale == 'en' ? idsEn : idsAr;
    final String? last = snapshot.lastGreetingId;
    int index = last == null
        ? 0
        : ((ids.indexOf(last) + 1) % ids.length).clamp(0, ids.length - 1);
    if (ids[index] == last) index = (index + 1) % ids.length;

    final String name = snapshot.childName.isEmpty
        ? (locale == 'en' ? 'champion' : 'يا بطل')
        : snapshot.childName;
    final String? achievement = snapshot.recentAchievements.isEmpty
        ? null
        : snapshot.recentAchievements.last;
    final bool weak = snapshot.weakLessonIds.isNotEmpty;

    String text;
    switch (ids[index]) {
      case 'g_en_1':
      case 'g_ar_1':
        text = locale == 'en'
            ? 'Hello $name! So nice to see you again.'
            : 'مرحباً $name! سعيد برؤيتك مرة أخرى.';
        break;
      case 'g_en_2':
      case 'g_ar_2':
        text = achievement == null
            ? (locale == 'en'
                ? 'Hi $name! Ready to discover something new together?'
                : 'أهلاً $name! مستعد نكتشف شيئاً جديداً معاً؟')
            : (locale == 'en'
                ? 'Well done $name on "$achievement"! Keep going.'
                : 'أحسنت يا $name على «$achievement»! أكمل رحلتك الرائعة.');
        break;
      case 'g_en_3':
      case 'g_ar_3':
        text = weak
            ? (locale == 'en'
                ? 'Hi $name! Shall we practice together a little?'
                : 'أهلاً $name! ما رأيك أن نتدرب معاً قليلاً؟')
            : (locale == 'en'
                ? 'Hi $name! Your last activity was fun — let\'s continue!'
                : 'أهلاً $name! كان نشاطك الماضي ممتعاً — هيا نكمل!');
        break;
      default:
        text = locale == 'en'
            ? 'Welcome back $name! Pick what you love and let\'s play.'
            : 'عوداً حميداً $name! اختر ما تحب ولنلعب معاً.';
    }
    return CompanionGreeting(ids[index], text, speakAllowed);
  }

  /// Marks a greeting as presented (persisted ONLY after successful
  /// presentation, per lifecycle contract). Returns the updated snapshot.
  static CompanionMemorySnapshot markGreetingPresented(
    CompanionMemorySnapshot snapshot,
    String greetingId,
  ) {
    return CompanionMemorySnapshot(
      childId: snapshot.childId,
      childName: snapshot.childName,
      preferredCompanion: snapshot.preferredCompanion,
      lastCompletedActivityId: snapshot.lastCompletedActivityId,
      unfinishedLessonId: snapshot.unfinishedLessonId,
      unfinishedSessionStartedAtIso: snapshot.unfinishedSessionStartedAtIso,
      recentAchievements: snapshot.recentAchievements,
      weakLessonIds: snapshot.weakLessonIds,
      lastInteractionContext: snapshot.lastInteractionContext,
      lastGreetingId: greetingId,
    );
  }

  /// Suggests (never executes, never claims completion) the session to
  /// resume: only the still-valid unfinished lesson, else the Phase 4
  /// bridge's next recommended lesson.
  static String suggestNextActivityId(
    CompanionMemorySnapshot snapshot,
    ChildProfile child,
  ) {
    if (snapshot.hasResumableSession(child.completedLessons.toSet())) {
      return snapshot.unfinishedLessonId!;
    }
    return LessonProgressBridge.analyze(child: child).nextLesson.id;
  }
}
