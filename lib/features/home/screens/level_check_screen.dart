import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class _Q {
  final String text;
  final List<String> options;
  final int correct;
  const _Q(this.text, this.options, this.correct);
}

/// A short, friendly level check (8 questions). The result sets the child's
/// curriculum tier (1-4). The parent can redo it from the path screen.
class LevelCheckScreen extends StatefulWidget {
  final AppStateManager appState;
  const LevelCheckScreen({super.key, required this.appState});
  @override
  State<LevelCheckScreen> createState() => _LevelCheckScreenState();
}

class _LevelCheckScreenState extends State<LevelCheckScreen> {
  static const List<_Q> _qs = [
    _Q('أي واحدة فيها ٣ تفاحات؟', ['🍎', '🍎🍎🍎', '🍎🍎🍎🍎🍎'], 1),
    _Q('أي حرف ده؟  ب', ['ب', 'ت', 'م'], 0),
    _Q('عُد النجوم: ⭐⭐⭐⭐⭐⭐⭐', ['٥', '٧', '٩'], 1),
    _Q('٣ + ٤ = ؟', ['٦', '٧', '٨'], 1),
    _Q('أي كلمة تبدأ بحرف (س)؟', ['سمكة', 'قطة', 'بطة'], 0),
    _Q('كمّل النمط: 🔴 🔵 🔴 🔵 🔴 ؟', ['🔴', '🔵', '🟢'], 1),
    _Q('١٢ - ٥ = ؟', ['٦', '٧', '٨'], 1),
    _Q('أي كلمة معناها عكس (كبير)؟', ['طويل', 'صغير', 'عالي'], 1),
  ];
  int _i = 0;
  int _score = 0;
  bool _done = false;

  int get _tier {
    if (_score >= 7) return 4;
    if (_score >= 5) return 3;
    if (_score >= 3) return 2;
    return 1;
  }

  Future<void> _answer(int o) async {
    if (o == _qs[_i].correct) _score++;
    if (_i == _qs.length - 1) {
      await widget.appState.applyLevelCheckTier(_tier);
      if (mounted) setState(() => _done = true);
    } else {
      setState(() => _i++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('اختبار المستوى')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _done ? _result() : _question(),
          ),
        ),
      ),
    );
  }

  Widget _result() => Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎉', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 10),
        Text(
            'برافو! جاوبت $_score من ${_qs.length}.\nهنجهّز لك دروس على قدّك.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('يلا نبدأ')),
      ]);

  Widget _question() {
    final _Q q = _qs[_i];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('سؤال ${_i + 1} من ${_qs.length}',
          style: const TextStyle(color: Colors.white54)),
      const SizedBox(height: 14),
      Text(q.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 22),
      for (int k = 0; k < q.options.length; k++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            width: 260,
            height: 56,
            child: ElevatedButton(
                onPressed: () => _answer(k),
                child: Text(q.options[k],
                    style: const TextStyle(fontSize: 22))),
          ),
        ),
    ]);
  }
}
