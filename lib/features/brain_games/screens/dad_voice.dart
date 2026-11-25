import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import 'package:haneen_kids_vod/core/theme/kid_theme.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Dad's (or mum's) recorded voice. The file stays in the app's private
/// folder on this phone. Nothing is uploaded or shared.
class DadVoiceCard extends StatefulWidget {
  final AppStateManager appState;
  const DadVoiceCard({super.key, required this.appState});
  @override
  State<DadVoiceCard> createState() => _DadVoiceCardState();
}

class _DadVoiceCardState extends State<DadVoiceCard> {
  AudioRecorder? _rec;
  VideoPlayerController? _player;
  bool _recording = false;
  bool _playing = false;
  bool _exists = false;
  String _msg = '';

  Future<File> _file() async {
    final Directory d = await getApplicationDocumentsDirectory();
    return File('${d.path}/dad_voice.m4a');
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final bool e = await (await _file()).exists();
      if (mounted) setState(() => _exists = e);
    } catch (_) {}
  }

  Future<void> _toggleRecord() async {
    try {
      _rec ??= AudioRecorder();
      if (_recording) {
        await _rec!.stop();
        setState(() {
          _recording = false;
          _msg = 'تم حفظ الصوت على الموبايل فقط ✅';
        });
        await _refresh();
        return;
      }
      if (!await _rec!.hasPermission()) {
        setState(() => _msg = 'محتاجين إذن الميكروفون عشان نسجّل');
        return;
      }
      final File f = await _file();
      await _rec!.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: f.path);
      setState(() {
        _recording = true;
        _msg = 'بنسجّل... اقرأ الحدوتة بصوتك 🎙️';
      });
    } catch (_) {
      setState(() {
        _recording = false;
        _msg = 'تعذّر التسجيل على الجهاز ده';
      });
    }
  }

  Future<void> _play() async {
    try {
      if (_playing) {
        await _player?.pause();
        setState(() => _playing = false);
        return;
      }
      final File f = await _file();
      await _player?.dispose();
      final VideoPlayerController c = VideoPlayerController.file(f);
      _player = c;
      await c.initialize();
      c.addListener(() {
        if (c.value.isInitialized && c.value.position >= c.value.duration && _playing && mounted) {
          setState(() => _playing = false);
        }
      });
      await c.play();
      setState(() => _playing = true);
    } catch (_) {
      setState(() => _msg = 'تعذّر تشغيل الصوت');
    }
  }

  Future<void> _delete() async {
    try {
      await _player?.dispose();
      _player = null;
      final File f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
    setState(() {
      _playing = false;
      _msg = 'تم مسح التسجيل';
    });
    await _refresh();
  }

  @override
  void dispose() {
    _player?.dispose();
    _rec?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('صوت بابا بيحكي 🎙️',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('سجّل حدوتة بصوتك، بتتحفظ على موبايل حنين بس',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      KidButton(
          label: _recording ? 'إيقاف التسجيل' : 'سجّل حدوتة',
          icon: _recording ? Icons.stop : Icons.mic,
          color: _recording ? const Color(0xFFEF4444) : KidTheme.info,
          onPressed: _toggleRecord),
      if (_exists && !_recording) ...[
        const SizedBox(height: 8),
        KidButton(
            label: _playing ? 'إيقاف مؤقت' : 'استمع لصوت بابا',
            icon: _playing ? Icons.pause : Icons.play_arrow,
            color: const Color(0xFF22C55E),
            onPressed: _play),
        TextButton(onPressed: _delete, child: const Text('مسح التسجيل', style: TextStyle(color: Colors.white70))),
      ],
      if (_msg.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))),
    ]);
  }
}
