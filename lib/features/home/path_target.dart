import 'package:flutter/foundation.dart';

/// Where a "مساري" step must open. [tab]: 0 stories, 1 academy, 2 games.
/// [trackId] picks the academy track chip; [gameIndex] picks the brain game.
class PathTarget {
  final int tab;
  final String? trackId;
  final int? gameIndex;
  const PathTarget(this.tab, {this.trackId, this.gameIndex});

  /// Set by مساري, consumed by the academy / games screens.
  static final ValueNotifier<PathTarget?> pending =
      ValueNotifier<PathTarget?>(null);
}
