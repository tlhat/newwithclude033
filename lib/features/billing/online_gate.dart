import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:flutter/foundation.dart';
import 'package:haneen_kids_vod/features/billing/billing_service.dart';

/// The app needs internet (subscription check with Google Play, payments,
/// premium services). When there is no connection a clear Arabic screen covers
/// the app until it comes back. Nothing about the child is sent: the check
/// only asks DNS for play.google.com.
class OnlineGate extends StatefulWidget {
  final Widget child;
  const OnlineGate({super.key, required this.child});

  @override
  State<OnlineGate> createState() => _OnlineGateState();
}

class _OnlineGateState extends State<OnlineGate> with WidgetsBindingObserver {
  bool _offline = false;
  bool _checking = false;
  Timer? _timer;

  static bool get _skip =>
      kIsWeb || !Platform.isAndroid || Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<bool> _reachable() async {
    try {
      final r = await InternetAddress.lookup('play.google.com')
          .timeout(const Duration(seconds: 5));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _check() async {
    if (_skip || _checking) return;
    _checking = true;
    final bool ok = await _reachable();
    _checking = false;
    if (!mounted) return;
    if (ok && _offline) {
      // Back online: refresh the subscription from Google Play.
      BillingService.instance.init();
    }
    if (ok == _offline) setState(() => _offline = !ok);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Material(
                color: const Color(0xFFFFF7E8),
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📶', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 14),
                          const Text('محتاجين إنترنت',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 10),
                          const Text(
                              'واحة اللعب والتعلم محتاجة اتصال بالإنترنت علشان تتحقق من اشتراكك. وصّل الواي فاي أو النت وارجع تاني.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15, color: Color(0xFF475569))),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              onPressed: _check,
                              child: const Text('جرّب تاني')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
