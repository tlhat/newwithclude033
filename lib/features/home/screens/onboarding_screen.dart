import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// First-run flow, redesigned: a welcome screen, then 4 short steps
/// (child + gender, age, daily time, parent PIN). Same data and same
/// `completeOneTimeInitialSetup` call as before, new look.
class OnboardingScreen extends StatefulWidget {
  final AppStateManager appState;
  const OnboardingScreen({super.key, required this.appState});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Lets tests reach the PIN rule without building the screen.
class OnboardingScreenTestHook {
  static bool isWeakPin(String pin) => _OnboardingScreenState.isWeakPin(pin);
}

Color _kNavy = Color(0xFF1E2A4A);
Color _kCream = Color(0xFFFFF7E8);
Color _kSkyTop = Color(0xFF6EC1FF);
Color _kSkyBottom = Color(0xFFCDEBFF);
List<Color> _kCoral = [Color(0xFFFF9577), Color(0xFFFF6B5B)];
List<Color> _kBlue = [Color(0xFF5BB0FA), Color(0xFF2F80ED)];

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  /// -1 is the welcome screen, 0..3 are the setup steps.
  int _currentStep = -1;
  String? _stepError;
  bool _isSaving = false;
  bool _termsAccepted = false;
  bool _hidePin = true;

  final TextEditingController _childNameCtrl = TextEditingController();
  String _selectedAge = '3–4 سنوات';
  String _selectedGender = 'boy';
  int _dailyUsageLimitMinutes = 25;
  final TextEditingController _passcodeCtrl = TextEditingController();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: Duration(seconds: 4),
  )..repeat();

  static List<Map<String, String>> _ageOptions = [
    {
      'value': '2–3 سنوات',
      'label': '٢ – ٣ سنوات',
      'sub': 'مرحلة الاكتشاف المبكر'
    },
    {
      'value': '3–4 سنوات',
      'label': '٣ – ٤ سنوات',
      'sub': 'مرحلة التأسيس والنطق'
    },
    {
      'value': '4–5 سنوات',
      'label': '٤ – ٥ سنوات',
      'sub': 'مرحلة المهارات والتفكير'
    },
    {
      'value': '5–6 سنوات',
      'label': '٥ – ٦ سنوات',
      'sub': 'مرحلة الاستعداد المدرسي'
    },
  ];

  /// PINs a child could guess.
  static bool isWeakPin(String pin) {
    if (pin.length != 6) return false;
    if (RegExp(r'^(\d)\1{5}$').hasMatch(pin)) return true; // 111111
    const String asc = '0123456789012345';
    const String desc = '9876543210987654';
    return asc.contains(pin) ||
        desc.contains(pin) ||
        pin == '123123' ||
        pin == '121212';
  }

  @override
  void dispose() {
    _float.dispose();
    _childNameCtrl.dispose();
    _passcodeCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    setState(() {
      _stepError = null;
      _currentStep = -1;
    });
  }

  Future<void> _next() async {
    setState(() => _stepError = null);

    // Fast start: the parent only sets the PIN. The child's name, age and
    // gender are asked lightly after the first game.
    if (_currentStep == -1) {
      setState(() => _currentStep = 3);
      return;
    }
    if (_currentStep == 0) {
      if (_childNameCtrl.text.trim().isEmpty) {
        setState(() => _stepError = 'اكتب اسم الطفل أولاً للمتابعة.');
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }
    if (_currentStep == 1 || _currentStep == 2) {
      setState(() => _currentStep++);
      return;
    }

    final String passcode =
        _passcodeCtrl.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (!ParentAccount.isValidParentalPinFormat(passcode)) {
      setState(() => _stepError =
          'الرمز السري لازم يكون ٦ أرقام بالضبط (كتبت ${passcode.length} من ٦).');
      return;
    }
    if (isWeakPin(passcode)) {
      setState(() => _stepError =
          'الرمز ده سهل التخمين. اختار ٦ أرقام مش متتالية ومش متكررة.');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _stepError = 'وافق على الشروط وسياسة الخصوصية للمتابعة.');
      return;
    }

    setState(() => _isSaving = true);
    final String? err = await widget.appState.completeOneTimeInitialSetup(
      childName: _childNameCtrl.text.trim().isEmpty
          ? 'بطل'
          : _childNameCtrl.text.trim(),
      childAge: _selectedAge,
      dailyTimeLimit: 0,
      parentPasscode6Digits: passcode,
      gender: _selectedGender,
      childIntroPending: true,
    );
    if (mounted) {
      setState(() {
        _isSaving = false;
        _stepError = err;
      });
    }
  }

  String get _avatarAsset => _selectedGender == 'girl'
      ? 'assets/avatars/girl_front.png'
      : 'assets/avatars/boy_front.png';

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final bool welcome = _currentStep == -1;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(brightness: Brightness.light),
        child: Scaffold(
          backgroundColor: _kSkyBottom,
          body: LayoutBuilder(builder: (context, c) {
            final double headerH = welcome
                ? math.min(c.maxHeight * 0.55, 470)
                : math.min(c.maxHeight * 0.26, 210);
            return Stack(
              children: [
                _SkyHeader(height: headerH, t: _float),
                if (welcome)
                  _welcomeHeroes(headerH, c.maxWidth)
                else
                  _stepHero(headerH),
                if (!welcome)
                  PositionedDirectional(
                    top: MediaQuery.of(context).padding.top + 6,
                    start: 8,
                    child: IconButton(
                      onPressed: _isSaving ? null : _goBack,
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 28),
                      tooltip: 'رجوع',
                    ),
                  ),
                Positioned(
                  top: headerH - 28,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kCream,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(34)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: welcome ? _welcomeBody() : _stepBody(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _welcomeHeroes(double headerH, double width) {
    // Two figures side by side, each about 0.62 * h wide.
    final double h = math.min(headerH * 0.98, width * 0.76);
    return Positioned(
      left: 0,
      right: 0,
      top: headerH - h - 20,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final double bob = math.sin(_float.value * math.pi * 2) * 4;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _heroImage('assets/avatars/girl_front.png', h),
                _heroImage('assets/avatars/boy_front.png', h),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The art files are square with empty side margins, so trim the sides.
  Widget _heroImage(String asset, double h) {
    return ClipRect(
      child: Align(
        widthFactor: 0.62,
        child: Image.asset(asset, height: h, cacheHeight: 700),
      ),
    );
  }

  Widget _stepHero(double headerH) {
    final double h = headerH * 1.1;
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).padding.top + 4,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final double bob = math.sin(_float.value * math.pi * 2) * 3;
          return Transform.translate(
            offset: Offset(0, bob),
            child: SizedBox(
              height: headerH - 36,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: (headerH - 36) / h,
                  child: Image.asset(_avatarAsset, height: h, cacheHeight: 700),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _restoringFromGoogle = false;

  /// Returning family on a new phone: sign in with Google and restore.
  Future<void> _restoreFromGoogle() async {
    setState(() => _restoringFromGoogle = true);
    final String? err = await widget.appState.signInWithGoogleAndRestore();
    if (!mounted) return;
    setState(() => _restoringFromGoogle = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
    // On success the app state changes and the router opens the app.
  }

  // -------------------------------------------------------------- welcome

  Widget _welcomeBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'أهلاً بيك في عالم حنين!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: _kNavy),
          ),
          const SizedBox(height: 8),
          const Text(
            'قصص وألعاب ذكاء ودروس حلوة تنمّي مهارات طفلك،\nمجاناً وبدون إعلانات',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF51608A)),
          ),
          const Spacer(),
          _GradientButton(
            label: 'يلا نبدأ!',
            colors: _kCoral,
            icon: Icons.arrow_back_rounded,
            onPressed: _next,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _restoringFromGoogle ? null : _restoreFromGoogle,
            icon: _restoringFromGoogle
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.account_circle_outlined, size: 20),
            label: Text('عندي حساب بالفعل (دخول بجوجل)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text('بإشراف الآباء والأمهات',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A86A6))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- steps

  Widget _stepBody() {
    final bool last = _currentStep == 3;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              0,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentStep == i ? 30 : 10,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= _currentStep
                      ? const Color(0xFFFF7A64)
                      : const Color(0xFFE3D9C6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
            child: _stepContent(),
          ),
        ),
        if (_stepError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFD9412F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_stepError!,
                        style: const TextStyle(
                            color: Color(0xFF8A2A1D), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: _GradientButton(
            label: last ? 'ابدأ رحلتي مع حنين' : 'التالي',
            colors: last ? _kBlue : _kCoral,
            loading: _isSaving,
            onPressed: _isSaving ? null : _next,
          ),
        ),
      ],
    );
  }

  Widget _title(String t, String sub) => Column(
        children: [
          Text(t,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: _kNavy)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: Color(0xFF6B7899))),
          const SizedBox(height: 16),
        ],
      );

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    OutlineInputBorder b(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF6B7899)),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF6B7899)),
      hintStyle: const TextStyle(color: Color(0xFFB0B8CC)),
      counterText: '',
      enabledBorder: b(const Color(0xFFD6E4F5)),
      focusedBorder: b(const Color(0xFF2F80ED), 1.8),
      border: b(const Color(0xFFD6E4F5)),
    );
  }

  Widget _stepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            _title('مين البطل الصغير؟', 'نخصص الترحيب والدروس والقصص باسمه'),
            TextField(
              controller: _childNameCtrl,
              style: TextStyle(color: _kNavy, fontSize: 16),
              textInputAction: TextInputAction.done,
              decoration: _decoration('اسم الطفل', Icons.badge_outlined,
                  hint: 'مثال: فارس أو ليلى'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _genderCard(
                        'boy', 'ولد', 'assets/avatars/boy_front.png')),
                const SizedBox(width: 12),
                Expanded(
                    child: _genderCard(
                        'girl', 'بنت', 'assets/avatars/girl_front.png')),
              ],
            ),
          ],
        );
      case 1:
        final String n = _childNameCtrl.text.trim();
        return Column(
          children: [
            _title('كام سنة ${n.isEmpty ? 'طفلك' : n}؟',
                'بنضبط صعوبة الألعاب والدروس على حسب السن'),
            for (final o in _ageOptions) _ageTile(o),
          ],
        );
      case 2:
        return Column(
          children: [
            _title(
                'وقت اللعب اليومي', 'حدد الدقائق المسموحة يومياً لراحة عينيه'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD6E4F5)),
              ),
              child: Column(
                children: [
                  Text('${_dailyUsageLimitMinutes} دقيقة',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF6B5B))),
                  Text('في اليوم',
                      style: TextStyle(color: Color(0xFF6B7899))),
                  Slider(
                    value: _dailyUsageLimitMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: const Color(0xFFFF6B5B),
                    label: '${_dailyUsageLimitMinutes} دقيقة',
                    onChanged: (v) =>
                        setState(() => _dailyUsageLimitMinutes = v.round()),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            _title('الرمز السري للوالدين',
                'بيفتح قسم الوالدين: الوقت والتقارير والإعدادات'),
            TextField(
              controller: _passcodeCtrl,
              keyboardType: TextInputType.number,
              obscureText: _hidePin,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                  color: _kNavy, fontSize: 20, letterSpacing: 6),
              decoration:
                  _decoration('٦ أرقام', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_hidePin
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _hidePin = !_hidePin),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('اختار رقم تفتكره ومش سهل على الطفل يخمنه.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7899))),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _termsAccepted,
                  activeColor: const Color(0xFF2F80ED),
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                ),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('أوافق على ',
                          style: TextStyle(fontSize: 13, color: _kNavy)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PrivacyPolicyScreen()),
                        ),
                        child: Text('سياسة الخصوصية',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2F80ED),
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _genderCard(String value, String label, String asset) {
    final bool sel = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF0EC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? const Color(0xFFFF6B5B) : const Color(0xFFD6E4F5),
              width: sel ? 2.4 : 1.2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 92,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: Image.asset(asset, height: 184, cacheHeight: 700),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (sel)
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: Color(0xFFFF6B5B)),
                if (sel) const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kNavy)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ageTile(Map<String, String> o) {
    final bool sel = _selectedAge == o['value'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedAge = o['value']!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFEAF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: sel ? const Color(0xFF2F80ED) : const Color(0xFFD6E4F5),
                width: sel ? 2.2 : 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o['label']!,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _kNavy)),
                    Text(o['sub']!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7899))),
                  ],
                ),
              ),
              Icon(
                sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: sel ? const Color(0xFF2F80ED) : const Color(0xFFB0B8CC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ pieces

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null && !loading ? 0.6 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: colors.last.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: Colors.white),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sky gradient with soft clouds and twinkling stars. Pure drawing, no assets.
class _SkyHeader extends StatelessWidget {
  final double height;
  final Animation<double> t;
  const _SkyHeader({required this.height, required this.t});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height + 20,
      child: AnimatedBuilder(
        animation: t,
        builder: (context, _) => CustomPaint(painter: _SkyPainter(t.value)),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double t;
  _SkyPainter(this.t);

  void _cloud(Canvas c, Offset o, double s, double a) {
    final Paint p = Paint()..color = Colors.white.withValues(alpha: a);
    c.drawCircle(o + Offset(0, 0), 16 * s, p);
    c.drawCircle(o + Offset(18 * s, -8 * s), 21 * s, p);
    c.drawCircle(o + Offset(40 * s, 0), 16 * s, p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx - 14 * s, o.dy, 70 * s, 16 * s),
        Radius.circular(8 * s),
      ),
      p,
    );
  }

  void _star(Canvas c, Offset o, double r, Color color, double rot) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double rad = i.isEven ? r : r * 0.45;
      final double a = -math.pi / 2 + i * math.pi / 5 + rot;
      final Offset pt = o + Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [_kSkyTop, _kSkyBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r),
    );
    final double w = size.width;
    final double drift = math.sin(t * math.pi * 2) * 8;
    _cloud(canvas, Offset(w * 0.08 + drift, size.height * 0.2), 1.0, 0.95);
    _cloud(canvas, Offset(w * 0.72 - drift, size.height * 0.12), 0.8, 0.85);
    _cloud(canvas, Offset(w * 0.78 + drift, size.height * 0.62), 1.1, 0.9);
    _cloud(canvas, Offset(w * 0.02 - drift, size.height * 0.7), 0.9, 0.9);

    const List<List<double>> stars = [
      [0.2, 0.1, 9, 0],
      [0.88, 0.3, 11, 1],
      [0.5, 0.06, 7, 2],
      [0.12, 0.45, 7, 3],
      [0.62, 0.5, 6, 4],
    ];
    for (final s in stars) {
      final double tw = 0.75 + 0.25 * math.sin(t * math.pi * 2 + s[3]);
      _star(canvas, Offset(w * s[0], size.height * s[1]), s[2] * tw,
          const Color(0xFFFFD54F), t * 0.6 * (s[3].toInt().isEven ? 1 : -1));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t;
}
