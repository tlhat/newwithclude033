import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

// Art files used here. All are optional: until the logo file exists the
// screen shows the word "حنين" drawn in code.
//   assets/icon/haneen_logo.png   (transparent PNG, about 1000 x 450)
// The two kids come from files already in the project:
//   assets/avatars/boy_front.png and assets/avatars/girl_front.png
const String _kLogoAsset = 'assets/icon/haneen_logo.png';
const String _kBoyAsset = 'assets/avatars/boy_front.png';
const String _kGirlAsset = 'assets/avatars/girl_front.png';

const Color _navy = Color(0xFF3A2A22);
const Color _cream = Color(0xFFFFF7E8);
const Color _gold = Color(0xFFF5B73B);

/// Sky header with clouds, floating decorations and the two kids.
class _GateHeader extends StatelessWidget {
  final double height;
  final bool showLogo;
  const _GateHeader({required this.height, required this.showLogo});

  Widget _deco(Widget w, {double? top, double? left, double? right}) =>
      Positioned(top: top, left: left, right: right, child: w);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _deco(
              const Icon(Icons.cloud_rounded, size: 70, color: Colors.white70),
              top: height * 0.30,
              left: -14),
          _deco(
              const Icon(Icons.cloud_rounded, size: 80, color: Colors.white70),
              top: height * 0.22,
              right: -18),
          _deco(const Icon(Icons.star_rounded, size: 30, color: _gold),
              top: height * 0.07, right: 70),
          _deco(
              const Icon(Icons.auto_awesome,
                  size: 16, color: Color(0xFFFFB24D)),
              top: height * 0.08,
              left: 60),
          _deco(
              const Icon(Icons.auto_awesome,
                  size: 14, color: Color(0xFFB59BFF)),
              top: height * 0.42,
              left: 14),
          if (showLogo) ...[
            _deco(
                Transform.rotate(
                    angle: -0.6,
                    child: const Icon(Icons.edit_rounded,
                        size: 40, color: Color(0xFFFFB24D))),
                top: height * 0.26,
                left: 30),
            _deco(
                const Text.rich(TextSpan(
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    children: [
                      TextSpan(
                          text: '1',
                          style: TextStyle(color: Color(0xFFE5589B))),
                      TextSpan(
                          text: '2',
                          style: TextStyle(color: Color(0xFFF5B73B))),
                      TextSpan(
                          text: '3',
                          style: TextStyle(color: Color(0xFF4CB86B))),
                    ])),
                top: height * 0.10,
                left: 20),
            _deco(
                Text('أ ب ت',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E8EDE))),
                top: height * 0.10,
                right: 20),
          ],
          // The two kids, standing on the bottom edge of the header.
          Positioned(
            bottom: -height * (showLogo ? 0.26 : 0.34),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
              children: [
                Align(
                  widthFactor: 0.62,
                  child: Image.asset(_kBoyAsset,
                      height: height * (showLogo ? 0.80 : 1.05),
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
                Align(
                  widthFactor: 0.62,
                  child: Image.asset(_kGirlAsset,
                      height: height * (showLogo ? 0.76 : 1.0),
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              ],
            ),
          ),
          if (showLogo)
            Positioned(
              top: height * 0.05,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(_kLogoAsset,
                    height: height * 0.30,
                    errorBuilder: (_, __, ___) => const _LogoFallback()),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();
  @override
  Widget build(BuildContext context) {
    String t = 'حنين';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      CustomPaint(size: const Size(34, 24), painter: _CrownPainter()),
      Stack(
        children: [
          Text(t,
              style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 8
                    ..color = const Color(0xFF3B2B8F))),
          Text(t,
              style: TextStyle(
                  fontSize: 56, fontWeight: FontWeight.w900, color: _gold)),
        ],
      ),
    ]);
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final Path p = Path()
      ..moveTo(0, z.height)
      ..lineTo(0, z.height * 0.25)
      ..lineTo(z.width * 0.25, z.height * 0.6)
      ..lineTo(z.width * 0.5, 0)
      ..lineTo(z.width * 0.75, z.height * 0.6)
      ..lineTo(z.width, z.height * 0.25)
      ..lineTo(z.width, z.height)
      ..close();
    c.drawPath(p, Paint()..color = _gold);
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFC98A12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The four-colour Google "G", drawn in code (no image file needed).
class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _GPainter());
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final double w = z.width;
    final double sw = w * 0.2;
    final Rect r =
        Rect.fromCircle(center: Offset(w / 2, w / 2), radius: w / 2 - sw / 2);
    Paint arc(Color col) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt
      ..color = col;
    const double pi = 3.141592653589793;
    // angles in radians, 0 = right, clockwise
    c.drawArc(r, pi * 0.25, pi * 0.5, false, arc(const Color(0xFF34A853)));
    c.drawArc(r, pi * 0.75, pi * 0.5, false, arc(const Color(0xFFFBBC05)));
    c.drawArc(r, pi * 1.25, pi * 0.5, false, arc(const Color(0xFFEA4335)));
    // blue: right side from the top-right down to the middle bar
    c.drawArc(r, -pi * 0.25, pi * 0.25, false, arc(const Color(0xFF4285F4)));
    c.drawRect(Rect.fromLTWH(w / 2, w / 2 - sw / 2, w / 2 - 0.5, sw),
        Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GateShell extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final String footer;
  final IconData footerIcon;
  const _GateShell({
    required this.child,
    required this.showLogo,
    required this.footer,
    required this.footerIcon,
  });

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double headerH = (h * (showLogo ? 0.40 : 0.27)).clamp(190.0, 380.0);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5CB6F5), Color(0xFFCDEBFF)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _GateHeader(height: headerH, showLogo: showLogo),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(
                        14, 0, 14, 14 + MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      color: _cream,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 14,
                            offset: Offset(0, 6))
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
                              child: child,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(footerIcon,
                                    size: 15, color: const Color(0xFF7A86A6)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(footer,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF7A86A6))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// First screen of the app: the parent signs in with Google (mandatory).
class GoogleGateScreen extends StatefulWidget {
  final AppStateManager appState;
  const GoogleGateScreen({super.key, required this.appState});

  @override
  State<GoogleGateScreen> createState() => _GoogleGateScreenState();
}

class _GoogleGateScreenState extends State<GoogleGateScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? err = await widget.appState.googleGateSignIn();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    // On success the app state changes and the router shows the next screen.
  }

  @override
  Widget build(BuildContext context) {
    return _GateShell(
      showLogo: true,
      footer: 'تحت إشراف الآباء والأمهات',
      footerIcon: Icons.verified_user_outlined,
      child: Column(
        children: [
          Text('أهلاً بك في عالم حنين!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: _navy)),
          const SizedBox(height: 10),
          Text(
            'ادخل بحساب جوجل الخاص بولي الأمر لحفظ تقدم طفلك ومتابعته على أي جهاز',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.5, height: 1.6, color: Color(0xFF51608A)),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E4F5)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 6,
                    offset: Offset(0, 3))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _busy ? null : _signIn,
                child: Center(
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4))
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _GoogleG(size: 26),
                              SizedBox(width: 12),
                              Text('الدخول بحساب جوجل',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _navy)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFD64545), fontSize: 13.5, height: 1.5)),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// Second screen on every launch: the parent's 6-digit PIN.
class PinUnlockScreen extends StatefulWidget {
  final AppStateManager appState;
  const PinUnlockScreen({super.key, required this.appState});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _pin = '';
  String? _error;

  void _tap(String d) {
    if (_pin.length >= ParentAccount.kUnifiedParentalPinLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == ParentAccount.kUnifiedParentalPinLength) _submit();
  }

  void _submit() {
    final String? err = widget.appState.unlockWithPin(_pin);
    if (err != null && mounted) {
      setState(() {
        _error = err;
        _pin = '';
      });
    }
  }

  Widget _key(String label, {VoidCallback? onTap, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Container(
        width: 76,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33B8A57A), blurRadius: 6, offset: Offset(0, 3))
          ],
          border: Border.all(color: const Color(0xFFF1E3C4)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: _navy)
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: _navy)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int n = ParentAccount.kUnifiedParentalPinLength;
    final String name = widget.appState.currentAccount?.activeChild.name ?? '';
    return _GateShell(
      showLogo: false,
      footer: 'حماية ولي الأمر • للآباء والأمهات',
      footerIcon: Icons.lock_outline,
      child: Column(
        children: [
          Text(name.isEmpty ? 'أهلاً بك في عالم حنين!' : 'أهلاً بك يا ${name}!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: _navy)),
          const SizedBox(height: 6),
          Text('اكتب الرمز السري الخاص بولي الأمر (٦ أرقام)',
              style: TextStyle(fontSize: 14, color: Color(0xFF51608A))),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.ltr,
            children: [
              for (int i = 0; i < n; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? _gold : const Color(0xFFDCEBF8),
                    border: Border.all(
                        color: i < _pin.length
                            ? const Color(0xFFE59A1E)
                            : const Color(0xFFBBD3EA),
                        width: 2),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 30,
            child: _error == null
                ? null
                : Center(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFD64545), fontSize: 13))),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                for (final row in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                ])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final d in row) _key(d, onTap: () => _tap(d)),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 86, height: 62),
                    _key('0', onTap: () => _tap('0')),
                    _key('', icon: Icons.backspace_outlined, onTap: () {
                      if (_pin.isNotEmpty) {
                        setState(
                            () => _pin = _pin.substring(0, _pin.length - 1));
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown on the child's phone when the parent locked the app remotely.
class RemoteLockScreen extends StatefulWidget {
  final AppStateManager appState;
  const RemoteLockScreen({super.key, required this.appState});

  @override
  State<RemoteLockScreen> createState() => _RemoteLockScreenState();
}

class _RemoteLockScreenState extends State<RemoteLockScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final String? e = await widget.appState.unlockRemoteLockWithPin(_ctrl.text);
    if (mounted && e != null) setState(() => _err = e);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E2A4A),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(widget.appState.remoteLockMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          height: 1.6,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ctrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: ParentAccount.kUnifiedParentalPinLength,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'الرمز السري لولي الأمر لفتح القفل',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_err!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                      onPressed: _unlock, child: Text('فتح القفل')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
