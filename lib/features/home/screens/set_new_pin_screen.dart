import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Shown after the family is restored from the Google backup on a phone that
/// is not the one that made it. The old PIN check cannot work here, so the
/// parent (already verified by Google sign-in) sets a new 6-digit PIN.
class SetNewPinScreen extends StatefulWidget {
  final AppStateManager appState;
  const SetNewPinScreen({super.key, required this.appState});

  @override
  State<SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends State<SetNewPinScreen> {
  final TextEditingController _a = TextEditingController();
  final TextEditingController _b = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_a.text != _b.text) {
      setState(() => _error = 'الرمزين مش زي بعض.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? err = await widget.appState.setNewPinAfterRestore(_a.text);
    if (mounted && err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 6,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, letterSpacing: 6),
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7E8),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_reset_rounded,
                        size: 56, color: Color(0xFF2F80ED)),
                    const SizedBox(height: 12),
                    const Text('رجّعنا بياناتك من جوجل ✅',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E2A4A))),
                    const SizedBox(height: 8),
                    const Text(
                        'الرمز السري القديم بيتحفظ على الموبايل القديم بس (لأمانك)، فاختار رمز جديد من ٦ أرقام لهذا الموبايل.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B7899))),
                    const SizedBox(height: 18),
                    _field(_a, 'الرمز الجديد (٦ أرقام)'),
                    const SizedBox(height: 12),
                    _field(_b, 'اكتبه تاني'),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? '...' : 'حفظ الرمز',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
