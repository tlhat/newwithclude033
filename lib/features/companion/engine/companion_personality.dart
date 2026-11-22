/// Immutable profile expressing how the companion behaves for a given
/// avatar gender. Phase 1 keeps both profiles behaviorally identical so the
/// current Haneen identity is fully preserved; the same engine serves both.
class CompanionPersonalityProfile {
  final String id;
  final CompanionGenderLike gender;

  /// Motion intensity multiplier applied by surfaces that choose to honor it.
  /// 1.0 = exactly current behavior.
  final double motionAmplitude;

  const CompanionPersonalityProfile({
    required this.id,
    required this.gender,
    this.motionAmplitude = 1.0,
  });
}

/// Mirrors `CompanionGender` without importing the model package, keeping
/// this file free of persistence dependencies.
enum CompanionGenderLike { boy, girl }

/// The two existing avatars. No new characters are introduced.
const Map<CompanionGenderLike, CompanionPersonalityProfile>
    kCompanionPersonalityProfiles = {
  CompanionGenderLike.boy: CompanionPersonalityProfile(
    id: 'haneen_boy',
    gender: CompanionGenderLike.boy,
  ),
  CompanionGenderLike.girl: CompanionPersonalityProfile(
    id: 'haneen_girl',
    gender: CompanionGenderLike.girl,
  ),
};

CompanionPersonalityProfile profileForGender(CompanionGenderLike gender) =>
    kCompanionPersonalityProfiles[gender] ??
    kCompanionPersonalityProfiles[CompanionGenderLike.boy]!;
