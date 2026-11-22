import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class LocalVideoDataSource {
  static const String kSavedVideosKey = 'saved_videos_v2';
  static const String kRemoteFeedUrlKey = 'remote_feed_url';

  final SharedPreferences _prefs;
  const LocalVideoDataSource(this._prefs);

  List<VideoModel> loadSavedVideosOrDefault() {
    final String? savedVideosJson = _prefs.getString(kSavedVideosKey);
    if (savedVideosJson != null && savedVideosJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(savedVideosJson);
        return list
            .map((item) =>
                VideoModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (_) {
        return getDefaultVideos();
      }
    }
    return getDefaultVideos();
  }

  Future<void> saveVideos(List<VideoModel> videos) async {
    final List<Map<String, dynamic>> data =
        videos.map((v) => v.toJson()).toList();
    await _prefs.setString(kSavedVideosKey, jsonEncode(data));
  }
}
