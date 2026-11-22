import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class AuthScreen extends StatefulWidget {
  final AppStateManager appState;
  const AuthScreen({super.key, required this.appState});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSubmitting = false;
  bool _isOtpStep = false;
  String? _errorMessage;
  String? _infoMessage;

  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _childNameCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  String _selectedAgeGroup = '3–6 سنوات';

  final List<String> _ageGroups = [
    '2–3 سنوات',
    '3–4 سنوات',
    '3–6 سنوات',
    '4–6 سنوات',
    '5–6 سنوات',
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _fullNameCtrl.dispose();
    _childNameCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final String phone = _phoneCtrl.text.trim();
    final String parent = _fullNameCtrl.text.trim();
    final String child = _childNameCtrl.text.trim();

    if (phone.isEmpty || parent.isEmpty || child.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إكمال جميع الحقول قبل طلب رمز التحقق.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _infoMessage = null;
      _isSubmitting = true;
    });

    final outcome = await widget.appState.requestPhoneAuthOtp(phone);
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (outcome.success) {
          _isOtpStep = true;
          _infoMessage = outcome.debugCode != null
              ? 'رمز التحقق التجريبي هو: ${outcome.debugCode}'
              : 'تم إرسال رمز التحقق OTP إلى هاتفك بنجاح.';
        } else {
          _errorMessage = outcome.errorMessage ?? 'تعذر إرسال رمز التحقق.';
        }
      });
    }
  }

  Future<void> _verifyOtpAndSubmit() async {
    final String otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() {
        _errorMessage = 'يرجى إدخال رمز التحقق المكون من 6 أرقام.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _infoMessage = null;
      _isSubmitting = true;
    });

    final String? error = await widget.appState.verifyOtpAndCompleteAuth(
      phoneNumber: _phoneCtrl.text.trim(),
      enteredOtp: otp,
      parentName: _fullNameCtrl.text.trim(),
      childName: _childNameCtrl.text.trim(),
      childAgeGroup: _selectedAgeGroup,
      clientIp: AuthSessionService.currentClientIp,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: KidFriendlyBigBackButton(
                        label: 'رجوع',
                        accentColor: const Color(0xFF38BDF8),
                        onPressed: () =>
                            widget.appState.reopenOnboardingIntro(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const HaneenAppIconPreviewWidget(size: 84),
                    const SizedBox(height: 12),
                    const Text(
                      'تسجيل الدخول وإنشاء الحساب',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.5)),
                      ),
                      child: const Text(
                        '✨ مجاني بالكامل ١٠٠٪ — بدون اشتراكات أو إعلانات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFDE68A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!_isOtpStep) ...[
                      // 1. رقم الموبايل
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الموبايل',
                          hintText: '01012345678',
                          prefixIcon: Icon(Icons.phone_iphone_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. اسم ولي الأمر
                      TextField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم ولي الأمر',
                          hintText: 'مثال: أحمد محمد',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. اسم الطفل
                      TextField(
                        controller: _childNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم الطفل',
                          hintText: 'مثال: فارس أو ليلى',
                          prefixIcon: Icon(Icons.child_care_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. سن الطفل
                      DropdownButtonFormField<String>(
                        value: _selectedAgeGroup,
                        decoration: const InputDecoration(
                          labelText: 'سن الطفل',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        items: _ageGroups
                            .map((age) => DropdownMenuItem(
                                  value: age,
                                  child: Text(age),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAgeGroup = val);
                          }
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF14B8A6).withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_rounded,
                                        color: Color(0xFF14B8A6), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _phoneCtrl.text.trim(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => setState(() => _isOtpStep = false),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('تعديل الرقم',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _otpCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5EEAD4),
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                labelText: 'رمز التحقق (OTP)',
                                hintText: '••••••',
                                prefixIcon: Icon(Icons.lock_clock_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_infoMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF0284C7).withOpacity(0.5)),
                        ),
                        child: Text(
                          _infoMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFFBAE6FD), fontSize: 12.5),
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
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
                                _errorMessage!,
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
                        onPressed: _isSubmitting
                            ? null
                            : (_isOtpStep ? _verifyOtpAndSubmit : _requestOtp),
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : Icon(_isOtpStep
                                ? Icons.verified_rounded
                                : Icons.send_to_mobile_rounded),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isOtpStep
                                    ? 'تأكيد الرمز وبدء الرحلة 🚀'
                                    : 'إرسال رمز التحقق (OTP) 📲',
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
