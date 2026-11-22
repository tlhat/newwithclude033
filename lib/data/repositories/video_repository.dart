import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class VideoRepository {
  final LocalVideoDataSource dataSource;
  final SupabaseRemoteDataSource? remoteDataSource;
  final OfflineSyncQueueService? syncQueue;

  const VideoRepository(
    this.dataSource, {
    this.remoteDataSource,
    this.syncQueue,
  });

  List<VideoModel> loadVideos() => dataSource.loadSavedVideosOrDefault();

  Future<void> saveVideos(List<VideoModel> videos) =>
      dataSource.saveVideos(videos);

  Future<void> enqueueVideoSync({
    required String parentEmail,
    required VideoModel video,
    String operation = 'upsert',
  }) async {
    if (syncQueue == null || parentEmail.trim().isEmpty) return;
    await syncQueue!.enqueueMutation(
      SyncMutationRecord(
        idempotencyKey: 'vid_${operation}_${video.id}_${video.isApprovedByParent ? "app" : "pend"}',
        parentEmail: parentEmail.trim().toLowerCase(),
        entityType: 'parent_video',
        entityId: video.id,
        operation: operation,
        payload: video.toJson(),
      ),
    );
  }

  List<VideoModel> filterApprovedForChild(
    List<VideoModel> allVideos, {
    required bool offlineOnly,
    required bool allowExternal,
    String selectedCategory = 'all',
  }) {
    final allowedList = allVideos.where((v) {
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

    if (selectedCategory == 'all') return allowedList;
    return allowedList.where((v) => v.category == selectedCategory).toList();
  }
}
