import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class ChildPolicySyncService {
  static const ChildProfileRepository _repo = ChildProfileRepository();

  static void syncActiveChild(ChildProfile? child) {
    _repo.syncActiveChildPoliciesToRuntime(child);
  }
}
