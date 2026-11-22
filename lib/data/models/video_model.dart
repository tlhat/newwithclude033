import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class VideoModel {
  final String id;
  final String linkedStoryId;
  final int durationSeconds;
  final String pedagogicalConcept;
  final String title;
  final String description;
  final String category;
  final String ageGroup;
  final String repeatPhrase;
  final String activeActivity;
  String streamUrl;
  String audioStreamUrl;
  final String originalSourceUrl;
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final String emoji;
  String autoFitMode;
  String qualityBadge;
  int likes;
  bool isLiked;
  bool isApprovedByParent;
  bool isBrokenStream;

  VideoModel({
    required this.id,
    String? linkedStoryId,
    this.durationSeconds = 216,
    this.pedagogicalConcept = 'التربية الأخلاقية والذكاء العاطفي',
    required this.title,
    required this.description,
    required this.category,
    required this.ageGroup,
    required this.repeatPhrase,
    required this.activeActivity,
    required this.streamUrl,
    this.audioStreamUrl = '',
    this.originalSourceUrl = '',
    this.bgGradientStart = const Color(0xFF1E1B4B),
    this.bgGradientEnd = const Color(0xFF0F172A),
    this.emoji = '🌟',
    this.autoFitMode = 'auto_cover',
    this.qualityBadge = 'قصة تفاعلية متحركة (٣–٥ د)',
    this.likes = 120,
    this.isLiked = false,
    this.isApprovedByParent = true,
    this.isBrokenStream = false,
  }) : linkedStoryId = linkedStoryId ?? id;

  InteractiveEducationalStoryModel get resolvedInteractiveStory =>
      AcademicStoriesRepository.findStoryForFeedItem(
        linkedStoryId,
        category: category,
      );

  static Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    String cleaned = hex.trim().replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final int? val = int.tryParse(cleaned, radix: 16);
    return val != null ? Color(val) : fallback;
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static String getCategoryDisplayLabel(String categoryKey) {
    switch (categoryKey) {
      case 'bedtime':
        return '🌙 قصص النوم التفاعلية';
      case 'habits':
        return '🧸 قصص السلوكيات والأخلاق';
      case 'arabic':
        return '🗣️ قصص الفصاحة والنطق';
      case 'science':
        return '🦋 قصص العلوم والطبيعة';
      case 'crafts':
        return '🎨 قصص الإبداع والمهارات';
      default:
        return categoryKey.isNotEmpty ? categoryKey : '✨ قصة تفاعلية متحركة';
    }
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final String rawCategory =
        (json['category'] ?? json['playlistId'] ?? 'bedtime').toString();
    final String idStr =
        (json['id'] ?? 'story_${DateTime.now().millisecondsSinceEpoch}')
            .toString();
    return VideoModel(
      id: idStr,
      linkedStoryId: (json['linkedStoryId'] ?? idStr).toString(),
      durationSeconds:
          int.tryParse(json['durationSeconds']?.toString() ?? '216') ?? 216,
      pedagogicalConcept:
          (json['pedagogicalConcept'] ?? 'التربية الأخلاقية والذكاء العاطفي')
              .toString(),
      title: (json['title'] ?? 'قصة تفاعلية متحركة').toString(),
      description: (json['description'] ?? json['subtitle'] ?? '').toString(),
      category: rawCategory,
      ageGroup:
          (json['ageGroup'] ?? json['ageRange'] ?? '3–6 سنوات').toString(),
      repeatPhrase: (json['repeatPhrase'] ??
              json['interactivePhrase'] ??
              '«أَنَا طِفْلٌ ذَكِيٌّ وَأَمِينٌ»')
          .toString(),
      activeActivity: (json['activeActivity'] ??
              json['offlineActivity'] ??
              'شارك ما تعلمته من القصة مع ماما أو بابا!')
          .toString(),
      streamUrl: (json['streamUrl'] ??
              json['hlsStreamUrl'] ??
              '/local/animated_stories/$idStr')
          .toString(),
      audioStreamUrl: (json['audioStreamUrl'] ?? '').toString(),
      originalSourceUrl: (json['originalSourceUrl'] ?? '').toString(),
      bgGradientStart: _parseHexColor(
          json['bgGradientStart']?.toString(), const Color(0xFF1E1B4B)),
      bgGradientEnd: _parseHexColor(
          json['bgGradientEnd']?.toString(), const Color(0xFF0F172A)),
      emoji: (json['emoji'] ?? '🌟').toString(),
      autoFitMode: (json['autoFitMode'] ?? 'auto_cover').toString(),
      qualityBadge:
          (json['qualityBadge'] ?? 'قصة تفاعلية متحركة (٣–٥ د)').toString(),
      likes: int.tryParse(json['likes']?.toString() ?? '150') ?? 150,
      isLiked: json['isLiked'] == true,
      isApprovedByParent: json['isApprovedByParent'] != false,
      isBrokenStream: json['isBrokenStream'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'linkedStoryId': linkedStoryId,
      'durationSeconds': durationSeconds,
      'pedagogicalConcept': pedagogicalConcept,
      'title': title,
      'description': description,
      'category': category,
      'ageGroup': ageGroup,
      'repeatPhrase': repeatPhrase,
      'activeActivity': activeActivity,
      'streamUrl': streamUrl,
      'audioStreamUrl': audioStreamUrl,
      'originalSourceUrl': originalSourceUrl,
      'playlistId': category,
      'categoryLabel': getCategoryDisplayLabel(category),
      'ageRange': ageGroup,
      'subtitle': description,
      'interactivePhrase': repeatPhrase,
      'offlineActivity': activeActivity,
      'bgGradientStart': _colorToHex(bgGradientStart),
      'bgGradientEnd': _colorToHex(bgGradientEnd),
      'emoji': emoji,
      'autoFitMode': autoFitMode,
      'qualityBadge': qualityBadge,
      'likes': likes,
      'isLiked': isLiked,
      'isApprovedByParent': isApprovedByParent,
      'isBrokenStream': isBrokenStream,
    };
  }
}

/// Replaces all legacy videos with the 100-500 Academic Interactive Animated Stories catalog!
List<VideoModel> getDefaultVideos() {
  return AcademicStoriesRepository.defaultCatalog.map((story) {
    final firstCard = story.storyCards.isNotEmpty ? story.storyCards.first : null;
    return VideoModel(
      id: story.id,
      linkedStoryId: story.id,
      durationSeconds: story.totalEstimatedDurationSeconds,
      pedagogicalConcept: story.pedagogicalConcept,
      title: story.title,
      description: story.partOneText,
      category: story.categoryId,
      ageGroup: story.ageGroup,
      repeatPhrase: '«${story.correctQuizAnswer}»',
      activeActivity: story.moralSummary,
      streamUrl: '/local/animated_stories/${story.id}',
      bgGradientStart: firstCard != null && firstCard.gradientColors.isNotEmpty
          ? firstCard.gradientColors.first
          : const Color(0xFF1E1B4B),
      bgGradientEnd: firstCard != null && firstCard.gradientColors.length > 1
          ? firstCard.gradientColors.last
          : const Color(0xFF0F172A),
      emoji: story.illustration,
      qualityBadge: 'قصة تفاعلية متحركة (${story.totalEstimatedMinutes} دقائق)',
      likes: 150 + (story.storyNumber * 3),
    );
  }).toList();
}
