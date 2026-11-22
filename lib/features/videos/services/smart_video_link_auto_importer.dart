import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class ImportedVideoSourceMetadata {
  final String? title;
  final String? originalDescription;
  final String? authorName;
  final String? hdStreamUrl;
  final String? separateAudioStreamUrl;
  final String sourceRawUrl;
  final String qualityBadge;
  final bool isVerticalSource;
  final bool resolvedRealStream;

  const ImportedVideoSourceMetadata({
    this.title,
    this.originalDescription,
    this.authorName,
    this.hdStreamUrl,
    this.separateAudioStreamUrl,
    required this.sourceRawUrl,
    this.qualityBadge = '1080p Full HD',
    this.isVerticalSource = true,
    this.resolvedRealStream = false,
  });
}

class SmartVideoLinkAutoImporter {
  static String stripPlatformMentions(String input) {
    final RegExp forbiddenPlatforms = RegExp(
      r'(youtube\s*shorts|youtube|youtu\.be|tiktok|tik\s*tok|انستقرام|انستغرام|فيسبوك|تيك\s*توك|تيكتوك|التيك\s*توك|التيكتوك|يوتيوب|اليوتيوب|شورتس|shorts|reels)',
      caseSensitive: false,
    );
    String cleaned = input.replaceAll(forbiddenPlatforms, '');
    cleaned = cleaned
        .replaceAll(RegExp(r'\(\s*\)'), '')
        .replaceAll(RegExp(r'\[\s*\]'), '')
        .replaceAll(RegExp(r'-\s*-'), '-')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    return cleaned;
  }

  static String? extractYouTubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts|live)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  static String? extractYouTubePlaylistId(String url) {
    final RegExp listRegex =
        RegExp(r'[?&]list=([a-zA-Z0-9_-]+)', caseSensitive: false);
    final match = listRegex.firstMatch(url.trim());
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  static bool isYouTubeChannelOrPlaylistUrl(String url) {
    final lower = url.toLowerCase().trim();
    if (!isYouTubeUrl(lower)) return false;
    return extractYouTubePlaylistId(url) != null;
  }

  static String? extractTikTokUsernameFromProfile(String url) {
    final String trimmed = Uri.decodeFull(url.trim());
    if (trimmed.startsWith('@') && !trimmed.contains('/')) {
      return trimmed.substring(1).trim();
    }
    if (!isTikTokUrl(trimmed)) return null;
    if (trimmed.toLowerCase().contains('/video/') ||
        trimmed.toLowerCase().contains('/photo/')) {
      return null;
    }
    final RegExp profileRegex =
        RegExp(r'tiktok\.com\/@([a-zA-Z0-9_.-]+)', caseSensitive: false);
    final match = profileRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  static Future<String> _resolveRedirectUrlIfNeeded(String rawUrl) async {
    String currentUrl = rawUrl.trim();
    if (!AppNetworkPolicyGuard.canPerformOutboundNetworkRequest(
        isVideoImportOrStream: true)) {
      return currentUrl;
    }
    if (currentUrl.startsWith('@') && !currentUrl.contains('/')) {
      return 'https://www.tiktok.com/$currentUrl';
    }
    final String lower = currentUrl.toLowerCase();
    if (!lower.contains('vm.tiktok.com') &&
        !lower.contains('vt.tiktok.com') &&
        !lower.contains('tiktok.com/t/')) {
      return currentUrl;
    }

    final client = http.Client();
    try {
      for (int hop = 0; hop < 5; hop++) {
        final req = http.Request('GET', Uri.parse(currentUrl))
          ..followRedirects = false
          ..headers['User-Agent'] =
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36';
        final streamed =
            await client.send(req).timeout(const Duration(seconds: 6));
        final String? loc = streamed.headers['location'];
        if (loc != null && loc.isNotEmpty) {
          if (loc.startsWith('http')) {
            currentUrl = loc;
          } else if (loc.startsWith('/')) {
            final uri = Uri.parse(currentUrl);
            currentUrl = '${uri.scheme}://${uri.host}$loc';
          }
          if (currentUrl.contains('/@') || currentUrl.contains('/video/')) {
            break;
          }
        } else {
          break;
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return currentUrl;
  }

  static Future<bool> detectIfChannelOrPlaylistUrl(String rawUrl) async {
    return extractYouTubePlaylistId(rawUrl) != null;
  }

  static bool isChannelOrPlaylistUrl(String url) {
    return extractYouTubePlaylistId(url) != null;
  }

  static bool isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  static bool isTikTokUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('tiktok.com') || lower.startsWith('@');
  }

  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .trim();
  }

  static String _normalizeAbsoluteTikwmUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final String u = rawUrl.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) return 'https://www.tikwm.com$u';
    return 'https://www.tikwm.com/$u';
  }

  static List<Map<String, String>> _extractTikwmVideoListFromResponse(
      dynamic decoded) {
    final List<Map<String, String>> results = [];
    if (decoded is! Map) return results;
    final dynamic dataNode = decoded['data'];
    List<dynamic>? rawList;
    if (dataNode is Map) {
      if (dataNode['videos'] is List) {
        rawList = dataNode['videos'] as List<dynamic>;
      } else if (dataNode['itemList'] is List) {
        rawList = dataNode['itemList'] as List<dynamic>;
      }
    } else if (dataNode is List) {
      rawList = dataNode;
    }
    if (rawList == null) return results;

    for (final v in rawList) {
      if (v is Map) {
        final String rawCaption =
            stripPlatformMentions((v['title'] ?? v['desc'] ?? '').toString());
        final String hdPlay =
            _normalizeAbsoluteTikwmUrl(v['hdplay']?.toString());
        final String play = _normalizeAbsoluteTikwmUrl(v['play']?.toString());
        final String wmPlay =
            _normalizeAbsoluteTikwmUrl(v['wmplay']?.toString());
        final String bestUrl = hdPlay.startsWith('http')
            ? hdPlay
            : (play.startsWith('http') ? play : wmPlay);
        final String videoIdStr =
            (v['video_id'] ?? v['aweme_id'] ?? v['id'] ?? '').toString();
        if (bestUrl.startsWith('http')) {
          results.add({
            'title': rawCaption.split('\n').first.trim(),
            'description': rawCaption,
            'streamUrl': bestUrl,
            'videoId': videoIdStr,
            'badge': hdPlay.startsWith('http') ? '1080p Full HD' : '720p HD',
          });
        }
      }
    }
    return results;
  }

  static Future<ImportedVideoSourceMetadata> fetchHighDefStreamAndExactMetadata(
      String rawUrl) async {
    final String rawTrimmed = rawUrl.trim();

    if (rawTrimmed.startsWith('/') || rawTrimmed.startsWith('file://')) {
      final String fileName =
          rawTrimmed.split('/').last.replaceAll('.mp4', '');
      return ImportedVideoSourceMetadata(
        title: fileName.isNotEmpty ? fileName : 'فيديو محلي عالي الدقة',
        originalDescription:
            'فيديو محلي بأعلى جودة أصلية من ذاكرة الجهاز ($fileName).',
        hdStreamUrl: rawTrimmed,
        sourceRawUrl: rawTrimmed,
        qualityBadge: 'Original 1080p HD',
        isVerticalSource: true,
        resolvedRealStream: true,
      );
    }

    if (!AppNetworkPolicyGuard.canPerformOutboundNetworkRequest(
        isVideoImportOrStream: true)) {
      return ImportedVideoSourceMetadata(
        title: null,
        originalDescription: null,
        hdStreamUrl: null,
        sourceRawUrl: rawTrimmed,
        qualityBadge: 'Offline Blocked',
        isVerticalSource: true,
        resolvedRealStream: false,
      );
    }

    final String trimmed = await _resolveRedirectUrlIfNeeded(rawTrimmed);

    if (trimmed.contains('drive.google.com/file/d/')) {
      final RegExp driveRegex =
          RegExp(r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)');
      final match = driveRegex.firstMatch(trimmed);
      if (match != null && match.groupCount >= 1) {
        final String fileId = match.group(1)!;
        return ImportedVideoSourceMetadata(
          title: 'قصة سحابية عالية الجودة',
          originalDescription: 'بث مرئي مباشر بالجودة الأصلية الكاملة.',
          hdStreamUrl: 'https://drive.google.com/uc?export=download&id=$fileId',
          sourceRawUrl: trimmed,
          qualityBadge: 'Original HD',
          isVerticalSource: true,
          resolvedRealStream: true,
        );
      }
    }

    if (isTikTokUrl(trimmed)) {
      String? ttTitle;
      String? ttDesc;
      String? ttAuthor;
      String? bestHdUrl;
      String badge = '1080p Full HD';

      try {
        final postRes = await http.post(
          Uri.parse('https://www.tikwm.com/api/'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
          },
          body: {'url': trimmed, 'hd': '1'},
        ).timeout(const Duration(seconds: 12));

        if (postRes.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(postRes.bodyBytes));
          if (decoded is Map && decoded['data'] is Map) {
            final dataMap = decoded['data'] as Map;
            final String? rawCaption = dataMap['title']?.toString().trim();
            if (rawCaption != null && rawCaption.isNotEmpty) {
              ttDesc = rawCaption;
              ttTitle = rawCaption.split('\n').first.trim();
            }
            if (dataMap['author'] is Map) {
              ttAuthor = (dataMap['author'] as Map)['nickname']?.toString();
            }
            final String hdPlay =
                _normalizeAbsoluteTikwmUrl(dataMap['hdplay']?.toString());
            final String play =
                _normalizeAbsoluteTikwmUrl(dataMap['play']?.toString());
            final String wmPlay =
                _normalizeAbsoluteTikwmUrl(dataMap['wmplay']?.toString());

            if (hdPlay.startsWith('http')) {
              bestHdUrl = hdPlay;
              badge = '1080p Full HD';
            } else if (play.startsWith('http')) {
              bestHdUrl = play;
              badge = '720p HD';
            } else if (wmPlay.startsWith('http')) {
              bestHdUrl = wmPlay;
              badge = 'HD';
            }
          }
        }
      } catch (_) {}

      if (bestHdUrl == null) {
        try {
          final getUri = Uri.parse(
              'https://www.tikwm.com/api/?url=${Uri.encodeComponent(trimmed)}&hd=1');
          final getRes = await http.get(
            getUri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36',
            },
          ).timeout(const Duration(seconds: 10));
          if (getRes.statusCode == 200) {
            final decoded = jsonDecode(utf8.decode(getRes.bodyBytes));
            if (decoded is Map && decoded['data'] is Map) {
              final dataMap = decoded['data'] as Map;
              final String? rawCaption = dataMap['title']?.toString().trim();
              if (rawCaption != null && rawCaption.isNotEmpty) {
                ttDesc ??= rawCaption;
                ttTitle ??= rawCaption.split('\n').first.trim();
              }
              final String hdPlay =
                  _normalizeAbsoluteTikwmUrl(dataMap['hdplay']?.toString());
              final String play =
                  _normalizeAbsoluteTikwmUrl(dataMap['play']?.toString());
              if (hdPlay.startsWith('http')) {
                bestHdUrl = hdPlay;
                badge = '1080p Full HD';
              } else if (play.startsWith('http')) {
                bestHdUrl = play;
                badge = '720p HD';
              }
            }
          }
        } catch (_) {}
      }

      if (ttTitle == null || ttDesc == null) {
        try {
          final oembedRes = await http
              .get(Uri.parse(
                  'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(trimmed)}'))
              .timeout(const Duration(seconds: 6));
          if (oembedRes.statusCode == 200) {
            final data = jsonDecode(utf8.decode(oembedRes.bodyBytes));
            if (data is Map) {
              final String? oTitle = data['title']?.toString().trim();
              ttAuthor ??= data['author_name']?.toString().trim();
              if (oTitle != null && oTitle.isNotEmpty) {
                ttDesc ??= oTitle;
                ttTitle ??= oTitle.split('\n').first.trim();
              }
            }
          }
        } catch (_) {}
      }

      return ImportedVideoSourceMetadata(
        title: ttTitle,
        originalDescription: ttDesc,
        authorName: ttAuthor,
        hdStreamUrl: bestHdUrl,
        sourceRawUrl: trimmed,
        qualityBadge: badge,
        isVerticalSource: true,
        resolvedRealStream: bestHdUrl != null,
      );
    }

    if (isYouTubeUrl(trimmed)) {
      String? ytTitle;
      String? ytDesc;
      String? ytAuthor;
      String? bestStreamUrl;
      String? separateAudioUrl;
      String badge = '1080p Full HD';
      bool isVertical = trimmed.toLowerCase().contains('/shorts/');


      if (bestStreamUrl == null) {
        final String? ytId = extractYouTubeVideoId(trimmed);
        if (ytId != null) {
          final List<String> pipedApis = [
            'https://pipedapi.kavin.rocks/streams/$ytId',
            'https://pipedapi.tokhmi.xyz/streams/$ytId',
            'https://inv.tux.pizza/api/v1/videos/$ytId',
          ];
          for (final api in pipedApis) {
            try {
              final res = await http
                  .get(Uri.parse(api))
                  .timeout(const Duration(seconds: 7));
              if (res.statusCode == 200) {
                final decoded = jsonDecode(utf8.decode(res.bodyBytes));
                if (decoded is Map) {
                  ytTitle ??= decoded['title']?.toString().trim();
                  ytDesc ??= decoded['description']?.toString().trim();
                  if (decoded['hls'] != null &&
                      decoded['hls'].toString().startsWith('http')) {
                    bestStreamUrl = decoded['hls'].toString();
                    badge = '1080p Adaptive HLS';
                    break;
                  }
                  if (decoded['formatStreams'] is List) {
                    for (final fs in (decoded['formatStreams'] as List)) {
                      if (fs is Map &&
                          fs['url'] != null &&
                          fs['url'].toString().startsWith('http')) {
                        bestStreamUrl = fs['url'].toString();
                        break;
                      }
                    }
                  }
                  if (bestStreamUrl != null) break;
                }
              }
            } catch (_) {}
          }
        }
      }

      if (ytTitle == null || ytDesc == null) {
        try {
          final oembedRes = await http
              .get(Uri.parse(
                  'https://www.youtube.com/oembed?url=${Uri.encodeComponent(trimmed)}&format=json'))
              .timeout(const Duration(seconds: 6));
          if (oembedRes.statusCode == 200) {
            final data = jsonDecode(utf8.decode(oembedRes.bodyBytes));
            if (data is Map) {
              ytTitle ??= data['title']?.toString().trim();
              ytAuthor ??= data['author_name']?.toString().trim();
            }
          }
        } catch (_) {}
      }

      return ImportedVideoSourceMetadata(
        title: ytTitle,
        originalDescription: ytDesc,
        authorName: ytAuthor,
        hdStreamUrl: bestStreamUrl,
        separateAudioStreamUrl: separateAudioUrl,
        sourceRawUrl: trimmed,
        qualityBadge: badge,
        isVerticalSource: isVertical,
        resolvedRealStream: bestStreamUrl != null,
      );
    }

    final bool isDirectLink = trimmed.startsWith('http');
    return ImportedVideoSourceMetadata(
      title: null,
      originalDescription: null,
      hdStreamUrl: isDirectLink ? trimmed : null,
      sourceRawUrl: trimmed,
      qualityBadge: '1080p HD',
      isVerticalSource: true,
      resolvedRealStream: isDirectLink,
    );
  }

  static String _cleanOriginalDescription(String? rawDesc, String fallbackTitle) {
    final String safeFallback = stripPlatformMentions(fallbackTitle);
    if (rawDesc == null || rawDesc.trim().isEmpty) {
      return safeFallback.isNotEmpty
          ? safeFallback
          : 'قصة مرئية هادئة وممتعة لأطفالنا الأبطال.';
    }
    String cleaned = rawDesc
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'https?:\/\/\S+'), '')
        .replaceAll(RegExp(r'#\S+'), '')
        .replaceAll(RegExp(r'\s{3,}'), '\n')
        .trim();
    cleaned = stripPlatformMentions(cleaned);
    return cleaned.isEmpty
        ? (safeFallback.isNotEmpty
            ? safeFallback
            : 'قصة مرئية هادئة وممتعة لأطفالنا الأبطال.')
        : cleaned;
  }

  static String _extractSmartRepeatPhraseFromContent(
      String title, String description, String category) {
    final String safeText = stripPlatformMentions('$title $description');
    final RegExp quotedMatch = RegExp(r'«([^»]{6,60})»|"([^"]{6,60})"');
    final m = quotedMatch.firstMatch(safeText);
    if (m != null) {
      final String extracted =
          stripPlatformMentions(m.group(1) ?? m.group(2) ?? '');
      if (extracted.isNotEmpty) {
        return '«$extracted»';
      }
    }

    final String cleanTitle = stripPlatformMentions(title)
        .replaceAll(RegExp(r'[#@|•\-_~]'), ' ')
        .trim();
    final List<String> titleWords =
        cleanTitle.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (titleWords.length >= 2 && titleWords.length <= 8) {
      return '«${titleWords.join(" ")}»';
    }

    switch (category) {
      case 'bedtime':
        return '«بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا، تُصْبِحُونَ عَلَى خَيْرٍ»';
      case 'arabic':
        return '«لُغَتِي العَرَبِيَّةُ جَمِيلَةٌ، وَأَنَا أَتَحَدَّثُ بِفَصَاحَةٍ»';
      case 'science':
        return '«سُبْحَانَ اللَّهِ الخَالِقِ العَظِيمِ، مَا أَجْمَلَ الطَّبِيعَةَ!»';
      case 'crafts':
        return '«أَنَا طِفْلٌ مُبْدِعٌ، أَصْنَعُ وَأَرْسُمُ بِيَدِي الجَمِيلَةِ»';
      default:
        return '«أَنَا بَطَلٌ مُؤَدَّبٌ، أُحِبُّ الخَيْرَ وَأُسَاعِدُ الجَمِيعَ»';
    }
  }

  static Map<String, dynamic> classifyAndGeneratePedagogicalMetadata({
    required String rawUrl,
    required ImportedVideoSourceMetadata sourceMeta,
  }) {
    final String rawTitle = stripPlatformMentions(sourceMeta.title?.trim() ?? '');
    final String rawDesc =
        stripPlatformMentions(sourceMeta.originalDescription?.trim() ?? '');
    final String combined = '$rawTitle $rawDesc'.toLowerCase();

    String category = 'habits';
    String ageGroup = '3–6 سنوات';
    String emoji = '🌟';
    String activeActivity = '';
    Color gradStart = const Color(0xFF1E1B4B);

    if (combined.contains('نوم') ||
        combined.contains('ليل') ||
        combined.contains('قمر') ||
        combined.contains('هادئ') ||
        combined.contains('sleep') ||
        combined.contains('bedtime') ||
        combined.contains('lullaby') ||
        combined.contains('moon')) {
      category = 'bedtime';
      ageGroup = '3–6 سنوات';
      emoji = '🌙';
      gradStart = const Color(0xFF1E1B4B);
      activeActivity =
          'خذ ٣ أنفاس عميقة وهادئة مع ماما أو بابا، وابتسم قبل إغماض عينيك للنوم الجميل.';
    } else if (combined.contains('حروف') ||
        combined.contains('عربي') ||
        combined.contains('نطق') ||
        combined.contains('قرآن') ||
        combined.contains('انشود') ||
        combined.contains('نشيد') ||
        combined.contains('كلمات') ||
        combined.contains('alphabet') ||
        combined.contains('arabic') ||
        combined.contains('learn')) {
      category = 'arabic';
      ageGroup = '2–6 سنوات';
      emoji = '🗣️';
      gradStart = const Color(0xFF312E81);
      activeActivity =
          'انطق ٣ كلمات عربية سمعتها في هذه القصة بصوت واضح أمام ماما أو بابا لتحصل على نجمة البطل!';
    } else if (combined.contains('حيوان') ||
        combined.contains('طبيع') ||
        combined.contains('بحر') ||
        combined.contains('فضاء') ||
        combined.contains('علوم') ||
        combined.contains('كيف') ||
        combined.contains('لماذا') ||
        combined.contains('animal') ||
        combined.contains('science') ||
        combined.contains('nature') ||
        combined.contains('space') ||
        combined.contains('dino')) {
      category = 'science';
      ageGroup = '4–8 سنوات';
      emoji = '🦋';
      gradStart = const Color(0xFF064E3B);
      activeActivity =
          'احكِ لماما أو بابا معلومة جديدة رأيتها في هذه القصة، وقلّد حركة الكائن اللطيف الذي ظهر فيها!';
    } else if (combined.contains('رسم') ||
        combined.contains('تلوين') ||
        combined.contains('اصنع') ||
        combined.contains('لعب') ||
        combined.contains('صلصال') ||
        combined.contains('رياضة') ||
        combined.contains('draw') ||
        combined.contains('craft') ||
        combined.contains('art') ||
        combined.contains('diy')) {
      category = 'crafts';
      ageGroup = '4–8 سنوات';
      emoji = '🎨';
      gradStart = const Color(0xFF78350F);
      activeActivity =
          'أحضر ورقة وألواناً أو مكعباتك الآن، وحاول رسم أو تقليد الشكل الجميل الذي شاهدته في القصة!';
    } else {
      category = 'habits';
      ageGroup = '3–6 سنوات';
      emoji = '🧸';
      gradStart = const Color(0xFF134E4A);
      activeActivity =
          'شارك ماما أو بابا أجمل فكرة تعلمتها من هذه القصة، ورتب ٣ أشياء في غرفتك بنشاط!';
    }

    String finalTitle = rawTitle
        .replaceAll(RegExp(r'#\S+'), '')
        .replaceAll('|', '—')
        .trim();
    if (finalTitle.isEmpty) {
      finalTitle = rawDesc.split('\n').first.trim();
    }
    finalTitle = stripPlatformMentions(finalTitle);
    if (finalTitle.length > 75) {
      finalTitle = '${finalTitle.substring(0, 72)}...';
    }
    if (finalTitle.isEmpty) {
      finalTitle = 'قصة حنين التربوية المصورة للأبطال';
    }

    final String exactOriginalDescription =
        _cleanOriginalDescription(rawDesc, finalTitle);

    final String repeatPhrase = _extractSmartRepeatPhraseFromContent(
      finalTitle,
      exactOriginalDescription,
      category,
    );

    final String smartFitMode =
        sourceMeta.isVerticalSource ? 'auto_cover' : 'contain';

    return {
      'title': finalTitle,
      'description': exactOriginalDescription,
      'category': category,
      'ageGroup': ageGroup,
      'repeatPhrase': repeatPhrase,
      'activeActivity': activeActivity,
      'emoji': emoji,
      'bgGradientStart': gradStart,
      'autoFitMode': smartFitMode,
      'qualityBadge': sourceMeta.qualityBadge,
    };
  }

  static Future<VideoModel?> autoImportAndGenerateFromUrl(
    String rawUrl, {
    String? preFetchedTitle,
    String? preFetchedDescription,
  }) async {
    final String cleanUrl = rawUrl.trim();
    final bool isLocalFile =
        cleanUrl.startsWith('/') || cleanUrl.startsWith('file://');
    if (!isLocalFile &&
        !AppNetworkPolicyGuard.canPerformOutboundNetworkRequest(
            isVideoImportOrStream: true)) {
      return null;
    }
    final ImportedVideoSourceMetadata fetchedMeta =
        await fetchHighDefStreamAndExactMetadata(cleanUrl);

    final String? finalTitle = fetchedMeta.title ?? preFetchedTitle;
    final String? finalDesc =
        fetchedMeta.originalDescription ?? preFetchedDescription ?? finalTitle;

    if (fetchedMeta.hdStreamUrl == null &&
        !isYouTubeUrl(cleanUrl) &&
        !isTikTokUrl(cleanUrl)) {
      return null;
    }

    final ImportedVideoSourceMetadata mergedMeta = ImportedVideoSourceMetadata(
      title: finalTitle,
      originalDescription: finalDesc,
      authorName: fetchedMeta.authorName,
      hdStreamUrl: fetchedMeta.hdStreamUrl,
      separateAudioStreamUrl: fetchedMeta.separateAudioStreamUrl,
      sourceRawUrl: cleanUrl,
      qualityBadge: fetchedMeta.qualityBadge,
      isVerticalSource: fetchedMeta.isVerticalSource,
      resolvedRealStream: fetchedMeta.resolvedRealStream,
    );

    final Map<String, dynamic> meta =
        classifyAndGeneratePedagogicalMetadata(
      rawUrl: cleanUrl,
      sourceMeta: mergedMeta,
    );

    return VideoModel(
      id: 'v_auto_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      title: meta['title'] as String,
      description: meta['description'] as String,
      category: meta['category'] as String,
      ageGroup: meta['ageGroup'] as String,
      repeatPhrase: meta['repeatPhrase'] as String,
      activeActivity: meta['activeActivity'] as String,
      streamUrl: fetchedMeta.hdStreamUrl ?? cleanUrl,
      audioStreamUrl: fetchedMeta.separateAudioStreamUrl ?? '',
      originalSourceUrl: cleanUrl,
      bgGradientStart: meta['bgGradientStart'] as Color,
      bgGradientEnd: const Color(0xFF0F172A),
      emoji: meta['emoji'] as String,
      autoFitMode: meta['autoFitMode'] as String,
      qualityBadge: meta['qualityBadge'] as String,
      likes: 150,
    );
  }

  static VideoModel _buildDeferredChannelVideoItem({
    required String watchUrl,
    required String rawTitle,
    required String rawDescription,
    required bool isVertical,
    required int indexOffset,
    String? directStreamUrl,
    String badge = '1080p Full HD',
  }) {
    final sourceMeta = ImportedVideoSourceMetadata(
      title: rawTitle,
      originalDescription: rawDescription.isNotEmpty ? rawDescription : rawTitle,
      hdStreamUrl: directStreamUrl,
      sourceRawUrl: watchUrl,
      qualityBadge: badge,
      isVerticalSource: isVertical,
      resolvedRealStream: directStreamUrl != null,
    );
    final meta = classifyAndGeneratePedagogicalMetadata(
      rawUrl: watchUrl,
      sourceMeta: sourceMeta,
    );
    return VideoModel(
      id: 'v_ch_${DateTime.now().millisecondsSinceEpoch}_$indexOffset',
      title: meta['title'] as String,
      description: meta['description'] as String,
      category: meta['category'] as String,
      ageGroup: meta['ageGroup'] as String,
      repeatPhrase: meta['repeatPhrase'] as String,
      activeActivity: meta['activeActivity'] as String,
      streamUrl: directStreamUrl ?? watchUrl,
      originalSourceUrl: watchUrl,
      bgGradientStart: meta['bgGradientStart'] as Color,
      bgGradientEnd: const Color(0xFF0F172A),
      emoji: meta['emoji'] as String,
      autoFitMode: meta['autoFitMode'] as String,
      qualityBadge: badge,
      likes: 165 + indexOffset * 9,
    );
  }

  static Future<String?> _resolveYouTubeChannelIdFromAnyUrl(
      String channelUrl) async {
    final RegExp directUcRegex =
        RegExp(r'youtube\.com\/channel\/(UC[a-zA-Z0-9_-]{20,28})');
    final directMatch = directUcRegex.firstMatch(channelUrl);
    if (directMatch != null) return directMatch.group(1);

    String cleanUrl = channelUrl.split('?').first.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    final List<String> urlsToTry = [
      if (!cleanUrl.endsWith('/videos') && !cleanUrl.endsWith('/shorts'))
        '$cleanUrl/videos',
      cleanUrl,
    ];

    for (final u in urlsToTry) {
      try {
        final res = await http.get(
          Uri.parse(u),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
            'Cookie': 'CONSENT=YES+cb.20230531-07-p0.en+FX+999',
          },
        ).timeout(const Duration(seconds: 9));

        if (res.statusCode == 200) {
          final html = utf8.decode(res.bodyBytes, allowMalformed: true);
          final RegExp ucRegex = RegExp(
              r'(?:"externalId"|"channelId"|"browseId"|channel_id=)\s*[:=]?\s*"?(UC[a-zA-Z0-9_-]{20,28})"?');
          final m = ucRegex.firstMatch(html);
          if (m != null && m.groupCount >= 1) {
            return m.group(1);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<List<VideoModel>> _parseYouTubeXmlFeed(
    String feedUrl, {
    required int maxCount,
    bool resolveFirstStreamImmediately = true,
  }) async {
    final List<VideoModel> results = [];
    try {
      final res = await http.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36',
        },
      ).timeout(const Duration(seconds: 9));

      if (res.statusCode == 200) {
        final xml = utf8.decode(res.bodyBytes, allowMalformed: true);
        final RegExp entryRegex =
            RegExp(r'<entry>([\s\S]*?)<\/entry>', caseSensitive: false);
        final matches = entryRegex.allMatches(xml).take(maxCount).toList();

        for (int i = 0; i < matches.length; i++) {
          final String entryXml = matches[i].group(1)!;
          final vidMatch =
              RegExp(r'<yt:videoId>([^<]+)<\/yt:videoId>').firstMatch(entryXml);
          final titleMatch =
              RegExp(r'<title>([\s\S]*?)<\/title>').firstMatch(entryXml);
          final descMatch = RegExp(
                  r'<media:description>([\s\S]*?)<\/media:description>')
              .firstMatch(entryXml);

          if (vidMatch != null) {
            final String vidId = vidMatch.group(1)!.trim();
            final String title =
                _decodeHtmlEntities(titleMatch?.group(1) ?? '');
            final String desc = _decodeHtmlEntities(descMatch?.group(1) ?? '');
            final String watchUrl = 'https://www.youtube.com/watch?v=$vidId';

            if (i == 0 && resolveFirstStreamImmediately) {
              final resolved = await autoImportAndGenerateFromUrl(
                watchUrl,
                preFetchedTitle: title,
                preFetchedDescription: desc,
              );
              if (resolved != null) {
                results.add(resolved);
                continue;
              }
            }

            results.add(
              _buildDeferredChannelVideoItem(
                watchUrl: watchUrl,
                rawTitle: title,
                rawDescription: desc,
                isVertical: false,
                indexOffset: i,
              ),
            );
          }
        }
      }
    } catch (_) {}
    return results;
  }

  static Future<List<VideoModel>> _scrapeTikTokProfilePageDirectly(
    String username, {
    required int maxVideosToImport,
  }) async {
    final List<VideoModel> scrapedList = [];
    final String cleanUser =
        username.startsWith('@') ? username.substring(1) : username;
    final String profileUrl = 'https://www.tiktok.com/@$cleanUser';

    try {
      final res = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 9));

      if (res.statusCode == 200) {
        final String html = utf8.decode(res.bodyBytes, allowMalformed: true);
        final Set<String> discoveredVideoIds = {};

        final RegExp urlVidRegex =
            RegExp(r'\/@[a-zA-Z0-9_.-]+\/video\/(\d{15,22})');
        for (final m in urlVidRegex.allMatches(html)) {
          discoveredVideoIds.add(m.group(1)!);
          if (discoveredVideoIds.length >= maxVideosToImport) break;
        }

        if (discoveredVideoIds.isEmpty) {
          final RegExp itemIdRegex =
              RegExp(r'"(?:id|video_id|aweme_id)"\s*:\s*"(\d{18,20})"');
          for (final m in itemIdRegex.allMatches(html)) {
            discoveredVideoIds.add(m.group(1)!);
            if (discoveredVideoIds.length >= maxVideosToImport) break;
          }
        }

        final List<String> idList =
            discoveredVideoIds.take(maxVideosToImport).toList();
        for (int i = 0; i < idList.length; i++) {
          final String vidId = idList[i];
          final String videoUrl =
              'https://www.tiktok.com/@$cleanUser/video/$vidId';
          if (i == 0) {
            final firstResolved =
                await autoImportAndGenerateFromUrl(videoUrl);
            if (firstResolved != null) {
              scrapedList.add(firstResolved);
              continue;
            }
          }
          String? oembedTitle;
          try {
            final oRes = await http
                .get(Uri.parse(
                    'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(videoUrl)}'))
                .timeout(const Duration(seconds: 4));
            if (oRes.statusCode == 200) {
              final data = jsonDecode(utf8.decode(oRes.bodyBytes));
              if (data is Map) {
                oembedTitle = data['title']?.toString().trim();
              }
            }
          } catch (_) {}

          scrapedList.add(
            _buildDeferredChannelVideoItem(
              watchUrl: videoUrl,
              rawTitle: oembedTitle?.split('\n').first.trim() ??
                  'قصة تربوية ممتعة (${i + 1})',
              rawDescription: oembedTitle ?? '',
              isVertical: true,
              indexOffset: i,
            ),
          );
        }
      }
    } catch (_) {}

    return scrapedList;
  }

  static Future<List<VideoModel>> autoImportChannelOrPlaylistFromUrl(
    String rawUrl, {
    int maxVideosToImport = 8,
  }) async {
    if (!AppNetworkPolicyGuard.canPerformOutboundNetworkRequest(
        isVideoImportOrStream: true)) {
      return [];
    }
    final String trimmed = await _resolveRedirectUrlIfNeeded(rawUrl.trim());
    final List<VideoModel> importedList = [];

    final String? ttUsername = extractTikTokUsernameFromProfile(trimmed);
    if (ttUsername != null) {
      final String cleanUser =
          ttUsername.startsWith('@') ? ttUsername.substring(1) : ttUsername;
      String? resolvedSecUid;
      String? resolvedUserId;

      try {
        final infoRes = await http.post(
          Uri.parse('https://www.tikwm.com/api/user/info'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36',
          },
          body: {'unique_id': cleanUser},
        ).timeout(const Duration(seconds: 8));

        if (infoRes.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(infoRes.bodyBytes));
          if (decoded is Map &&
              decoded['data'] is Map &&
              (decoded['data'] as Map)['user'] is Map) {
            final userMap = (decoded['data'] as Map)['user'] as Map;
            resolvedSecUid = userMap['secUid']?.toString();
            resolvedUserId = userMap['id']?.toString();
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 1150));

      final List<Map<String, String>> postPayloads = [
        {
          'unique_id': cleanUser,
          if (resolvedSecUid != null && resolvedSecUid.isNotEmpty)
            'secUid': resolvedSecUid,
          if (resolvedUserId != null && resolvedUserId.isNotEmpty)
            'user_id': resolvedUserId,
          'count': '12',
          'cursor': '0',
          'hd': '1',
        },
        {
          'unique_id': '@$cleanUser',
          'count': '12',
          'cursor': '0',
          'hd': '1',
        },
      ];

      for (final bodyMap in postPayloads) {
        try {
          final postRes = await http.post(
            Uri.parse('https://www.tikwm.com/api/user/posts'),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36',
            },
            body: bodyMap,
          ).timeout(const Duration(seconds: 12));

          if (postRes.statusCode == 200) {
            final decoded = jsonDecode(utf8.decode(postRes.bodyBytes));
            final extracted = _extractTikwmVideoListFromResponse(decoded);
            for (int i = 0;
                i < extracted.take(maxVideosToImport).length;
                i++) {
              final item = extracted[i];
              final String vidId = item['videoId'] ?? '';
              importedList.add(
                _buildDeferredChannelVideoItem(
                  watchUrl: vidId.isNotEmpty
                      ? 'https://www.tiktok.com/@$cleanUser/video/$vidId'
                      : trimmed,
                  rawTitle: item['title'] ?? '',
                  rawDescription: item['description'] ?? '',
                  isVertical: true,
                  indexOffset: i,
                  directStreamUrl: item['streamUrl'],
                  badge: item['badge'] ?? '1080p Full HD',
                ),
              );
            }
          }
        } catch (_) {}

        if (importedList.isNotEmpty) return importedList;
        await Future.delayed(const Duration(milliseconds: 1150));
      }

      try {
        final searchRes = await http.post(
          Uri.parse('https://www.tikwm.com/api/feed/search'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36',
          },
          body: {
            'keywords': cleanUser,
            'count': '12',
            'cursor': '0',
            'hd': '1',
          },
        ).timeout(const Duration(seconds: 11));

        if (searchRes.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(searchRes.bodyBytes));
          final extracted = _extractTikwmVideoListFromResponse(decoded);
          for (int i = 0; i < extracted.take(maxVideosToImport).length; i++) {
            final item = extracted[i];
            final String vidId = item['videoId'] ?? '';
            importedList.add(
              _buildDeferredChannelVideoItem(
                watchUrl: vidId.isNotEmpty
                    ? 'https://www.tiktok.com/@$cleanUser/video/$vidId'
                    : trimmed,
                rawTitle: item['title'] ?? '',
                rawDescription: item['description'] ?? '',
                isVertical: true,
                indexOffset: i,
                directStreamUrl: item['streamUrl'],
                badge: item['badge'] ?? '1080p Full HD',
              ),
            );
          }
        }
      } catch (_) {}

      if (importedList.isNotEmpty) return importedList;

      final scraped = await _scrapeTikTokProfilePageDirectly(
        cleanUser,
        maxVideosToImport: maxVideosToImport,
      );
      if (scraped.isNotEmpty) return scraped;
    }

    if (isYouTubeUrl(trimmed)) {
      final String? playlistId = extractYouTubePlaylistId(trimmed);

      if (playlistId != null) {
        final xmlItems = await _parseYouTubeXmlFeed(
          'https://www.youtube.com/feeds/videos.xml?playlist_id=$playlistId',
          maxCount: maxVideosToImport,
        );
        if (xmlItems.isNotEmpty) return xmlItems;

        if (importedList.isNotEmpty) return importedList;
      }

      final String? channelId =
          await _resolveYouTubeChannelIdFromAnyUrl(trimmed);
      if (channelId != null) {
        final xmlItems = await _parseYouTubeXmlFeed(
          'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId',
          maxCount: maxVideosToImport,
        );
        if (xmlItems.isNotEmpty) return xmlItems;

        if (importedList.isNotEmpty) return importedList;
      }

      try {
        String scrapeUrl = trimmed.split('?').first;
        if (!scrapeUrl.endsWith('/videos') &&
            !scrapeUrl.endsWith('/shorts') &&
            !scrapeUrl.contains('watch')) {
          scrapeUrl = '$scrapeUrl/videos';
        }
        final pageRes = await http.get(
          Uri.parse(scrapeUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
            'Accept-Language': 'ar,en;q=0.9',
            'Cookie': 'CONSENT=YES+cb.20230531-07-p0.en+FX+999',
          },
        ).timeout(const Duration(seconds: 9));

        if (pageRes.statusCode == 200) {
          final html = utf8.decode(pageRes.bodyBytes, allowMalformed: true);
          final RegExp vidMatches = RegExp(r'"videoId":"([a-zA-Z0-9_-]{11})"');
          final List<String> ids = [];
          for (final m in vidMatches.allMatches(html)) {
            final String id = m.group(1)!;
            if (!ids.contains(id)) {
              ids.add(id);
              if (ids.length >= maxVideosToImport) break;
            }
          }
          for (int i = 0; i < ids.length; i++) {
            final String watchUrl = 'https://www.youtube.com/watch?v=${ids[i]}';
            if (i == 0) {
              final firstResolved =
                  await autoImportAndGenerateFromUrl(watchUrl);
              if (firstResolved != null) {
                importedList.add(firstResolved);
                continue;
              }
            }
            String? quickTitle;
            try {
              final oembedRes = await http
                  .get(Uri.parse(
                      'https://www.youtube.com/oembed?url=${Uri.encodeComponent(watchUrl)}&format=json'))
                  .timeout(const Duration(seconds: 4));
              if (oembedRes.statusCode == 200) {
                final data = jsonDecode(utf8.decode(oembedRes.bodyBytes));
                if (data is Map) {
                  quickTitle = data['title']?.toString().trim();
                }
              }
            } catch (_) {}
            importedList.add(
              _buildDeferredChannelVideoItem(
                watchUrl: watchUrl,
                rawTitle: quickTitle ?? 'قصة تربوية ممتعة (${i + 1})',
                rawDescription: quickTitle ?? '',
                isVertical: scrapeUrl.endsWith('/shorts'),
                indexOffset: i,
              ),
            );
          }
        }
      } catch (_) {}

      if (importedList.isNotEmpty) return importedList;
    }

    final single = await autoImportAndGenerateFromUrl(trimmed);
    if (single != null) {
      importedList.add(single);
    }
    return importedList;
  }
}
