library haneen_kids_exports;

export 'app/app.dart';
export 'app/app_initializer.dart';
export 'app/app_routes.dart';
export 'app/app_theme.dart';

export 'core/config/supabase_env_config.dart';
export 'core/config/app_environment_config.dart';
export 'core/config/feature_flags.dart';
export 'core/localization/locale_controller.dart';
export 'core/sync/offline_sync_engine.dart';
export 'core/constants/app_constants.dart';
export 'core/errors/app_failures.dart';
export 'core/network/app_network_policy_guard.dart';
export 'core/security/local_credential_security_service.dart';
export 'core/security/google_oauth_verification_service.dart';
export 'core/security/subscription_entitlement_security_service.dart';
export 'core/storage/local_preferences_storage.dart';
export 'core/utils/arabic_text_utils.dart';
export 'core/services/elevenlabs_voice_service.dart';
export 'core/services/calm_voice_service.dart';
export 'core/services/section_intro_service.dart';
export 'core/services/google_account_service.dart';
export 'features/home/widgets/google_backup_card.dart';
export 'features/videos/widgets/animated_story_scene.dart';

export 'data/models/video_model.dart';
export 'data/models/child_profile_model.dart';
export 'features/companion/models/avatar_customization_model.dart';
export 'data/models/parent_account_model.dart';
export 'data/datasources/local_account_datasource.dart';
export 'data/datasources/local_video_datasource.dart';
export 'data/datasources/supabase_remote_datasource.dart';
export 'data/repositories/account_repository.dart';
export 'data/repositories/child_profile_repository.dart';
export 'data/repositories/video_repository.dart';
export 'data/repositories/subscription_repository.dart';

export 'features/authentication/screens/auth_screen.dart';
export 'features/authentication/services/auth_session_service.dart';
export 'features/authentication/widgets/auth_header_badge.dart';

export 'features/child_profiles/models/child_profile_exports.dart';
export 'features/child_profiles/screens/multi_child_profiles_screen.dart';
export 'features/child_profiles/services/child_policy_sync_service.dart';
export 'features/child_profiles/widgets/child_profile_card_widget.dart';

export 'features/home/screens/onboarding_screen.dart';
export 'features/home/screens/main_navigation_shell.dart';
export 'features/home/screens/achievements_center_tab.dart';
export 'features/home/screens/child_account_tab.dart';
export 'features/home/models/cute_hero_character_model.dart';
export 'features/home/widgets/interactive_3d_superhero_avatar.dart';
export 'features/home/widgets/cute_superhero_companion_banner.dart';

export 'features/videos/services/smart_video_link_auto_importer.dart';
export 'features/videos/screens/vertical_video_feed_player_screen.dart';
export 'features/videos/widgets/vertical_video_feed_item_widget.dart';

export 'features/pronunciation/models/pronunciation_evaluation.dart';
export 'features/pronunciation/services/pronunciation_coach_service.dart';
export 'features/pronunciation/screens/pronunciation_practice_sheet.dart';

export 'features/activities/models/academy_track_lesson_model.dart';
export 'features/activities/models/interactive_educational_story_model.dart';
export 'features/activities/services/adaptive_learning_engine.dart';
export 'features/activities/services/lesson_attempt_ledger.dart';
export 'features/activities/services/lesson_progress_bridge.dart';
export 'features/companion/engine/companion_memory.dart';
export 'features/activities/services/hint_ladder.dart';
export 'features/activities/screens/haneen_academy_screen.dart';
export 'features/activities/widgets/etiquette_drawing_canvas_painter.dart';

export 'features/brain_games/models/brain_game_models.dart';
export 'features/brain_games/services/hundred_level_games_generator.dart';
export 'features/brain_games/services/educational_ai_tutor_service.dart';
export 'features/brain_games/games/brain_games_catalog.dart';
export 'features/brain_games/screens/brain_games_hub_screen.dart';

export 'features/parental_studio/screens/parental_studio_screen.dart';
export 'features/parental_studio/services/remote_child_monitor_service.dart';
export 'features/parental_studio/widgets/monitor_stat_badge.dart';
export 'features/parental_studio/widgets/parent_beta_feedback_card.dart';

export 'features/subscriptions/models/subscription_models.dart';
export 'features/subscriptions/services/strict_egyptian_payment_validator.dart';
export 'features/subscriptions/screens/subscription_plans_section.dart';

export 'features/settings/screens/account_settings_section.dart';
export 'features/settings/widgets/security_settings_card.dart';

export 'shared/components/app_state_manager.dart';
export 'shared/components/star_reward_host.dart';
export 'features/parental_studio/screens/parent_progress_report.dart';
export 'features/parental_studio/widgets/safety_privacy_card.dart';
export 'shared/widgets/side_action_button.dart';
export 'shared/widgets/kid_friendly_big_back_button.dart';
export 'shared/widgets/app_common_widgets.dart';
export 'features/companion/models/avatar_customization_model.dart';
export 'features/companion/widgets/haneen_companion_avatar_widget.dart';
export 'features/companion/widgets/haneen_rive_avatar_widget.dart';
export 'features/companion/widgets/companion_guide_overlay.dart';
export 'features/companion/screens/character_studio_screen.dart';
export 'features/companion/engine/speech_coordinator.dart';
export 'shared/dialogs/parental_pin_gate_dialog.dart';
