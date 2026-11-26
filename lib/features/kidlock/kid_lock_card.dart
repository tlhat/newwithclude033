import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'kid_lock.dart';

/// Parent area card: child lock. Turning it off asks for the parent PIN again.
class KidLockCard extends StatefulWidget {
  final AppStateManager appState;
  const KidLockCard({super.key, required this.appState});
  @override
  State<KidLockCard> createState() => _KidLockCardState();
}

class _KidLockCardState extends State<KidLockCard> {
  KidLockStatus _s = const KidLockStatus();
  bool _watchdog = true;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final KidLockStatus s = await KidLock.status();
    if (mounted) setState(() => _s = s);
  }

  Future<bool> _askPin() async {
    final TextEditingController c = TextEditingController();
    String err = '';
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('أدخل رمز الأب لفك القفل'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: c,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(hintText: 'الرمز'),
              ),
              if (err.isNotEmpty) Text(err, style: const TextStyle(color: Colors.red)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              TextButton(
                onPressed: () {
                  final String? e = widget.appState.unlockWithPin(c.text);
                  if (e == null) {
                    Navigator.pop(ctx, true);
                  } else {
                    set(() => err = e);
                  }
                },
                child: const Text('فك القفل'),
              ),
            ],
          ),
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _enable() async {
    final KidLockStatus s = await KidLock.enable(watchdog: _watchdog);
    // Make the parent area ask for the PIN again.
    widget.appState.pinUnlockedThisSession = false;
    if (!mounted) return;
    setState(() {
      _s = s;
      _msg = s.pinned || s.deviceOwner
          ? 'القفل شغّال. وافق على رسالة "تثبيت الشاشة" لو ظهرت. للخروج: الرمز من منطقة الأب.'
          : 'لو ما ظهرتش رسالة تثبيت الشاشة، فعّلها من إعدادات الأندرويد (الأمان > تثبيت الشاشة) وجرب تاني.';
    });
    // Go back to the child's side.
    Navigator.of(context).maybePop();
  }

  Future<void> _disable() async {
    if (!await _askPin()) return;
    final KidLockStatus s = await KidLock.disable();
    if (mounted) setState(() { _s = s; _msg = 'تم فك القفل.'; });
  }

  Future<void> _release() async {
    if (!await _askPin()) return;
    final KidLockStatus s = await KidLock.releaseDeviceOwner();
    if (mounted) setState(() { _s = s; _msg = 'تم إلغاء وضع الجهاز المخصص.'; });
  }

  Widget _small(String t, {Color c = Colors.white60}) => Text(t, style: TextStyle(color: c, fontSize: 12));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          type: MaterialType.transparency,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔒 قفل الطفل',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            _small('يخلّي الطفل جوه حنين، ومفيش خروج إلا برمز الأب. كل ده على الجهاز بدون إنترنت.'),
            const SizedBox(height: 8),
            Text('الحالة: ${_s.strengthLabel}', style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 14)),
            if (!KidLock.supported) _small('القفل متاح على أندرويد فقط.'),
            const SizedBox(height: 8),
            if (!KidLock.on.value)
              ElevatedButton.icon(
                onPressed: KidLock.supported ? _enable : null,
                icon: const Icon(Icons.lock),
                label: const Text('تفعيل قفل الطفل'),
              )
            else
              ElevatedButton.icon(
                onPressed: _disable,
                icon: const Icon(Icons.lock_open),
                label: const Text('فك القفل (بالرمز)'),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('حارس الرجوع للتطبيق', style: TextStyle(color: Colors.white)),
              subtitle: _small('لو الطفل خرج، التطبيق يحاول يرجع. بيشتغل على بعض الأجهزة بس.'),
              value: _watchdog,
              onChanged: (v) async {
                setState(() => _watchdog = v);
                await KidLock.setWatchdog(v);
              },
            ),
            const SizedBox(height: 4),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              _small('الشاشة الرئيسية: ${_s.defaultHome ? 'حنين' : 'ليست حنين'}  ', c: Colors.white70),
              TextButton(
                onPressed: () async {
                  await KidLock.setHomeAlias(true);
                  await KidLock.openHomeSettings();
                  await _refresh();
                },
                child: const Text('اجعل حنين الشاشة الرئيسية'),
              ),
            ]),
            _small('زر الرئيسية يرجّع لحنين بدل شاشة الموبايل. اختر "حنين كيدز" من القائمة التي تظهر.'),
            if (_s.deviceOwner) ...[
              const SizedBox(height: 8),
              _small('الجهاز مُجهّز كجهاز مخصص: أقوى قفل، ولا يخرج الطفل حتى بالأزرار.', c: const Color(0xFFFCD34D)),
              TextButton(onPressed: _release, child: const Text('إلغاء وضع الجهاز المخصص (بالرمز)')),
            ] else
              _small('للقفل الكامل المحكم: جهّز الجهاز كجهاز مخصص مرة واحدة. الشرح في docs/KID_LOCK.md.'),
            if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: _small(_msg, c: Colors.white)),
          ]),
        ),
      ),
    );
  }
}
