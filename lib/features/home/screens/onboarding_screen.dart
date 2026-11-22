import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// One-Time Initial Installation Setup Flow (`OnboardingScreen`):
/// Appears strictly once upon initial installation and takes the user sequentially through:
/// 1. Entering the Child's Name -> tap Next
/// 2. Selecting the Child's Age -> tap Next
/// 3. Setting Daily Usage Limits -> tap Next
/// 4. Creating a 12-Digit Parent Passcode -> Finish (never reappears on subsequent launches).
class OnboardingScreen extends StatefulWidget {
  final AppStateManager appState;
  const OnboardingScreen({super.key, required this.appState});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0: Name, 1: Age, 2: Daily Limit, 3: 12-Digit Passcode
  String? _stepError;
  bool _isSaving = false;

  final TextEditingController _childNameCtrl = TextEditingController();
  String _selectedAge = '3–4 سنوات';
  String _selectedGender = 'boy';
  int _dailyUsageLimitMinutes = 25;
  final TextEditingController _passcode12Ctrl = TextEditingController();

  static const List<Map<String, String>> _ageOptions = [
    {'value': '2–3 سنوات', 'label': '٢ – ٣ سنوات (مرحلة الاكتشاف المبكر)', 'emoji': '🐣'},
    {'value': '3–4 سنوات', 'label': '٣ – ٤ سنوات (مرحلة التأسيس والنطق)', 'emoji': '🐰'},
    {'value': '4–5 سنوات', 'label': '٤ – ٥ سنوات (مرحلة المهارات والتفكير)', 'emoji': '🦁'},
    {'value': '5–6 سنوات', 'label': '٥ – ٦ سنوات (مرحلة الاستعداد المدرسي)', 'emoji': '🚀'},
  ];

  @override
  void dispose() {
    _childNameCtrl.dispose();
    _passcode12Ctrl.dispose();
    super.dispose();
  }

  void _goBackStep() {
    if (_currentStep > 0) {
      setState(() {
        _stepError = null;
        _currentStep--;
      });
    }
  }

  Future<void> _handleNextOrFinish() async {
    setState(() {
      _stepError = null;
    });

    if (_currentStep == 0) {
      if (_childNameCtrl.text.trim().isEmpty) {
        setState(() {
          _stepError = 'يرجى كتابة اسم الطفل أولاً للمتابعة.';
        });
        return;
      }
      setState(() {
        _currentStep = 1;
      });
      return;
    }

    if (_currentStep == 1) {
      if (_selectedAge.trim().isEmpty) {
        setState(() {
          _stepError = 'يرجى اختيار سن الطفل للمتابعة.';
        });
        return;
      }
      setState(() {
        _currentStep = 2;
      });
      return;
    }

    if (_currentStep == 2) {
      setState(() {
        _currentStep = 3;
      });
      return;
    }

    // Step 3: Validate 12-Digit Parent Passcode & complete one-time setup
    final String passcode =
        _passcode12Ctrl.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (!ParentAccount.isValidParentalPinFormat(passcode)) {
      setState(() {
        _stepError =
            'يرجى إدخال رمز سري للوالدين مكوّن من ٦ أرقام بالضبط (تم إدخال ${passcode.length} من ٦).';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String? err = await widget.appState.completeOneTimeInitialSetup(
      childName: _childNameCtrl.text.trim(),
      childAge: _selectedAge,
      dailyTimeLimit: _dailyUsageLimitMinutes,
      parentPasscode6Digits: passcode,
      gender: _selectedGender,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _stepError = err;
      });
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '١. ما هو اسم بطلنا الصغير؟ 🌟',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم تخصيص الترحيب الصوتي والدروس والقصص باسم طفلك.',
              style: TextStyle(fontSize: 13.5, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _childNameCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleNextOrFinish(),
              decoration: const InputDecoration(
                labelText: 'اسم الطفل',
                hintText: 'مثال: فارس أو ليلى',
                prefixIcon: Icon(Icons.child_care_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'الجنس:',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  avatar: const Text('👦'),
                  label: const Text('ولد'),
                  selected: _selectedGender == 'boy',
                  selectedColor: const Color(0xFF6C63FF).withOpacity(0.35),
                  onSelected: (val) {
                    if (val) setState(() => _selectedGender = 'boy');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Text('👧'),
                  label: const Text('بنت'),
                  selected: _selectedGender == 'girl',
                  selectedColor: const Color(0xFFFF7892).withOpacity(0.35),
                  onSelected: (val) {
                    if (val) setState(() => _selectedGender = 'girl');
                  },
                ),
              ],
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '٢. كم عمر ${_childNameCtrl.text.trim()}؟ 🎂',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر الفئة العمرية لضبط صعوبة الألعاب والمستوى التعليمي تلقائياً:',
              style: TextStyle(fontSize: 13.5, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            ..._ageOptions.map((opt) {
              final bool isSelected = _selectedAge == opt['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _selectedAge = opt['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF14B8A6).withOpacity(0.22)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF14B8A6)
                            : Colors.white12,
                        width: isSelected ? 2.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(opt['emoji']!,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt['label']!,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF14B8A6)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '٣. تحديد وقت الاستخدام اليومي ⏱️',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'حدد عدد الدقائق المسموح بها يومياً لراحة عيني طفلك وتنظيم وقته:',
              style: TextStyle(fontSize: 13.5, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFF14B8A6).withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_dailyUsageLimitMinutes دقيقة يومياً',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _dailyUsageLimitMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: const Color(0xFF14B8A6),
                    label: '$_dailyUsageLimitMinutes دقيقة',
                    onChanged: (v) =>
                        setState(() => _dailyUsageLimitMinutes = v.round()),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '٤. إنشاء الرمز السري للوالدين (٦ أرقام) 🔐',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يُستخدم هذا الرمز المكون من ٦ أرقام لفتح قسم الوالدين وتعديل وقت الاستخدام ومتابعة نشاط الطفل:',
              style: TextStyle(fontSize: 13.5, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _passcode12Ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'الرمز السري للوالدين (٦ أرقام)',
                hintText: 'أدخل ٦ أرقام (مثال: 123456)',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          KidFriendlyBigBackButton(
                            compact: true,
                            labelAr: 'السابق',
                            onPressed: _goBackStep,
                          )
                        else
                          const HaneenAppIconPreviewWidget(size: 52),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14B8A6).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    const Color(0xFF14B8A6).withOpacity(0.5)),
                          ),
                          child: Text(
                            'إعداد لمرة واحدة (${_currentStep + 1} من ٤)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA7F3D0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'مرحباً بكم في حنين كيدز (مجاني ١٠٠٪)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentStep == i ? 32 : 12,
                          height: 9,
                          decoration: BoxDecoration(
                            color: i <= _currentStep
                                ? const Color(0xFF14B8A6)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: _buildStepContent(),
                    ),
                    if (_stepError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _stepError!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSaving ? null : _handleNextOrFinish,
                        icon: Icon(_currentStep < 3
                            ? Icons.arrow_forward_rounded
                            : Icons.check_circle_outline_rounded),
                        label: Text(
                          _currentStep < 3
                              ? 'التالي'
                              : 'بدء استخدام حنين كيدز مجاناً 🚀',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
