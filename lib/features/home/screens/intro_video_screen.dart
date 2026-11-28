import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/safe_mode.dart';
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/core/services/calm_voice_service.dart';
import 'package:haneen_kids_vod/features/home/screens/intro_tour_screen.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// First-launch intro video, shown once before the Google sign-in gate.
/// Plays the bundled clip full-screen with a skip button always visible.
/// If the video cannot play on this phone (codec or player failure), the
/// illustrated IntroTourScreen is shown instead, so the gate is never blocked.
class IntroVideoScreen extends StatefulWidget {
  final AppStateManager appState;
  final VoidCallback onDone;
  const IntroVideoScreen(
      {super.key, required this.appState, required this.onDone});

  static const String seenKey = 'intro_video_seen_v1';

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _ctrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    SafeMode.risk();
    if (CalmVoiceService.isRunningInUnitTest) {
      // No codec in tests: fall back to the illustrated intro.
      _failed = true;
      return;
    }
    final VideoPlayerController c =
        VideoPlayerController.asset('assets/video/intro.mp4');
    _ctrl = c;
    c.initialize().then((_) {
      if (!mounted) return;
      if (c.value.hasError) {
        setState(() => _failed = true);
        return;
      }
      setState(() {});
      c.play();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
    c.addListener(_watch);
  }

  void _watch() {
    final VideoPlayerController? c = _ctrl;
    if (!mounted || c == null) return;
    if (c.value.hasError) {
      setState(() => _failed = true);
      return;
    }
    final Duration pos = c.value.position;
    final Duration dur = c.value.duration;
    if (dur > Duration.zero && pos >= dur) {
      _finish();
    }
  }

  Future<void> _finish() async {
    try {
      await _ctrl?.pause();
    } catch (_) {}
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(IntroVideoScreen.seenKey, true);
    } catch (_) {}
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_watch);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return IntroTourScreen(appState: widget.appState, onDone: _finish);
    }
    final VideoPlayerController? c = _ctrl;
    final bool ready = c != null && c.value.isInitialized && !c.value.hasError;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c!.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              )
            else
              const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: const Color(0x66000000)),
                    onPressed: _finish,
                    child: const Text('تخطّي',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
