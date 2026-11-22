import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class RemoteChildMonitorService {
  const RemoteChildMonitorService();

  Map<String, dynamic> buildLiveStatusPayload(
      ChildProfile child, String latestAction) {
    return {
      'event': 'child_activity_update',
      'childId': child.id,
      'childName': child.name,
      'currentLiveStatus': child.currentLiveStatus,
      'isLocked': child.isDeviceRemotelyLocked,
      'usedMinutesToday': child.usedMinutesToday,
      'starsEarned': child.starsEarned,
      'intelligencePoints': child.intelligencePoints,
      'latestAction': latestAction,
    };
  }
}
