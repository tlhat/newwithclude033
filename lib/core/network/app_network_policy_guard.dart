class AppNetworkPolicyGuard {
  static bool isOfflineOnlyModeActive = false;
  static bool isExternalVideosAllowed = true;
  static bool reduceMotionActive = false;
  static bool highContrastActive = false;
  static bool soundAndVoiceActive = true;
  static bool lowMemoryPerformanceModeActive = false;
  static int blockedNetworkRequestsCount = 0;

  static const List<String> kTrustedVideoAndFeedHosts = [
    'flutter.github.io',
    'github.io',
    'raw.githubusercontent.com',
    'drive.google.com',
    'docs.google.com',
    'vimeo.com',
    'player.vimeo.com',
    'cloudflarestream.com',
    'akamaized.net',
    'cloudfront.net',
  ];

  static bool canPerformOutboundNetworkRequest({
    bool isVideoImportOrStream = false,
  }) {
    if (isOfflineOnlyModeActive) {
      blockedNetworkRequestsCount++;
      return false;
    }
    if (isVideoImportOrStream && !isExternalVideosAllowed) {
      blockedNetworkRequestsCount++;
      return false;
    }
    return true;
  }

  static bool isPrivateOrLoopbackHost(String host) {
    final String h = host.trim().toLowerCase();
    if (h.isEmpty ||
        h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '0.0.0.0' ||
        h == '::1' ||
        h == '[::1]' ||
        h.endsWith('.local') ||
        h.endsWith('.internal')) {
      return true;
    }
    if (h.startsWith('10.') ||
        h.startsWith('192.168.') ||
        h.startsWith('169.254.') ||
        h.startsWith('127.')) {
      return true;
    }
    final RegExp rfc1918Block172 = RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.');
    if (rfc1918Block172.hasMatch(h)) return true;
    return false;
  }

  static bool isSafeLocalFilePath(String rawPath) {
    final String trimmed = rawPath.trim();
    if (trimmed.contains('..') || trimmed.contains('\u0000')) return false;
    return trimmed.startsWith('/') ||
        trimmed.toLowerCase().startsWith('file://');
  }

  static bool isTrustedHttpsVideoOrFeedUrl(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return false;
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      return false;
    }
    final String host = uri.host.toLowerCase();
    if (isPrivateOrLoopbackHost(host)) return false;
    for (final String trusted in kTrustedVideoAndFeedHosts) {
      if (host == trusted || host.endsWith('.$trusted')) {
        return true;
      }
    }
    return false;
  }

  static bool isSecureHttpsOrLocalFile(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (isSafeLocalFilePath(trimmed)) return true;
    return isTrustedHttpsVideoOrFeedUrl(trimmed);
  }
}
