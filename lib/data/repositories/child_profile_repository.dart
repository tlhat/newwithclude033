import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class ChildProfileRepository {
  final SupabaseRemoteDataSource? remoteDataSource;
  final OfflineSyncQueueService? syncQueue;

  const ChildProfileRepository({
    this.remoteDataSource,
    this.syncQueue,
  });

  void syncActiveChildPoliciesToRuntime(ChildProfile? child) {
    if (child == null) return;
    AppNetworkPolicyGuard.isOfflineOnlyModeActive = child.offlineOnlyMode;
    AppNetworkPolicyGuard.isExternalVideosAllowed = child.allowExternalVideos;
    AppNetworkPolicyGuard.reduceMotionActive = child.reduceMotion;
    AppNetworkPolicyGuard.highContrastActive = child.highContrastMode;
    AppNetworkPolicyGuard.soundAndVoiceActive = child.allowSoundEffectsAndVoice;
    AppNetworkPolicyGuard.lowMemoryPerformanceModeActive =
        child.lowMemoryPerformanceMode;
    CalmVoiceService.instance.setChildMicrophoneAllowed(child.allowMicrophone);
    CalmVoiceService.instance
        .setSoundAndVoiceEnabled(child.allowSoundEffectsAndVoice);
    CalmVoiceService.instance.configureChildVoicePreferences(
      personaId: child.preferredVoicePersonaId,
      dialect: child.preferredVoiceDialect,
      speed: child.preferredVoiceSpeed,
    );
  }

  void evaluateAndUnlockAchievements(ChildProfile child) {
    final String nowIso = DateTime.now().toIso8601String();
    if (child.completedLessons.isNotEmpty &&
        !child.unlockedAchievements.containsKey('first_lesson')) {
      child.unlockedAchievements['first_lesson'] = nowIso;
    }
    if (child.completedLessons.length >= 5 &&
        !child.unlockedAchievements.containsKey('five_lessons')) {
      child.unlockedAchievements['five_lessons'] = nowIso;
    }
    if (child.practicedVocabulary.length >= 5 &&
        !child.unlockedAchievements.containsKey('vocab_explorer')) {
      child.unlockedAchievements['vocab_explorer'] = nowIso;
    }
    if (child.gamesCompletedCount >= 5 &&
        !child.unlockedAchievements.containsKey('games_champion')) {
      child.unlockedAchievements['games_champion'] = nowIso;
    }
    if (child.starsEarned >= 15 &&
        !child.unlockedAchievements.containsKey('star_collector_15')) {
      child.unlockedAchievements['star_collector_15'] = nowIso;
    }
    if (child.correctPronunciationsCount >= 3 &&
        !child.unlockedAchievements.containsKey('clear_speaker')) {
      child.unlockedAchievements['clear_speaker'] = nowIso;
    }
    if ((child.gameProgressByGameId['memory_match_lvl'] ?? 0) >= 2 &&
        !child.unlockedAchievements.containsKey('memory_master')) {
      child.unlockedAchievements['memory_master'] = nowIso;
    }
    if (((child.gameProgressByGameId['pattern_logic'] ?? 0) +
                (child.gameProgressByGameId['odd_one_out'] ?? 0)) >=
            2 &&
        !child.unlockedAchievements.containsKey('logic_detective')) {
      child.unlockedAchievements['logic_detective'] = nowIso;
    }
    if ((child.gameProgressByGameId['visual_math'] ?? 0) >= 2 &&
        !child.unlockedAchievements.containsKey('math_genius')) {
      child.unlockedAchievements['math_genius'] = nowIso;
    }
    if (((child.gameProgressByGameId['classify'] ?? 0) +
                (child.gameProgressByGameId['pic_match'] ?? 0)) >=
            2 &&
        !child.unlockedAchievements.containsKey('classification_expert')) {
      child.unlockedAchievements['classification_expert'] = nowIso;
    }
    if ((child.gameProgressByGameId['etiquette_draw'] ?? 0) >= 2 &&
        !child.unlockedAchievements.containsKey('kind_etiquette_hero')) {
      child.unlockedAchievements['kind_etiquette_hero'] = nowIso;
    }
    if (child.currentCurriculumTier >= 3 &&
        !child.unlockedAchievements.containsKey('tier_up_champion')) {
      child.unlockedAchievements['tier_up_champion'] = nowIso;
    }
  }

  ChildProfile resolveConflict({
    required ChildProfile local,
    required ChildProfile remote,
  }) {
    return ChildSyncConflictResolver.resolveConflict(
      local: local,
      remote: remote,
    );
  }

  Future<bool> enqueueChildMutation({
    required String idempotencyKey,
    required String parentEmail,
    required String childId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    if (syncQueue == null) return false;
    return syncQueue!.enqueueMutation(
      SyncMutationRecord(
        idempotencyKey: idempotencyKey,
        parentEmail: parentEmail.trim().toLowerCase(),
        childId: childId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
      ),
    );
  }

  Future<void> clearActivityHistoryOnServerAndQueue({
    required String parentEmail,
    required String sessionAccessToken,
    required String childId,
  }) async {
    await enqueueChildMutation(
      idempotencyKey:
          'clear_history_${childId}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      parentEmail: parentEmail,
      childId: childId,
      entityType: 'child_activity_logs',
      entityId: childId,
      operation: 'clear_history',
      payload: {'childId': childId},
    );
    if (remoteDataSource != null) {
      await remoteDataSource!.invokeServerRpc(
        rpcName: 'rpc_clear_child_activity_history_only',
        sessionAccessToken: sessionAccessToken,
        params: {'p_child_id': childId},
      );
    }
  }

  Future<bool> deleteAllChildDataOnServerAndQueue({
    required String parentEmail,
    required String sessionAccessToken,
    required String childId,
    required bool removeProfile,
  }) async {
    if (syncQueue != null) {
      await syncQueue!.removePendingMutationsForChild(childId);
    }

    bool serverConfirmed = false;
    if (remoteDataSource != null &&
        remoteDataSource!.canConnectToSupabase &&
        sessionAccessToken.trim().isNotEmpty) {
      final res = await remoteDataSource!.invokeServerRpc(
        rpcName: 'rpc_delete_all_child_data',
        sessionAccessToken: sessionAccessToken,
        params: {
          'p_child_id': childId,
          'p_remove_profile': removeProfile,
        },
      );
      serverConfirmed = res != null;
    } else {
      // In offline mode: queue the deletion securely to sync on reconnect
      await enqueueChildMutation(
        idempotencyKey:
            'delete_all_${childId}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
        parentEmail: parentEmail,
        childId: childId,
        entityType: 'child_profile',
        entityId: childId,
        operation: removeProfile ? 'delete_profile' : 'delete_all_child_data',
        payload: {'childId': childId, 'removeProfile': removeProfile},
      );
      serverConfirmed = true;
    }
    return serverConfirmed;
  }
}
