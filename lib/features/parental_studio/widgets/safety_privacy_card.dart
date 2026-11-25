import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/core/security/local_credential_security_service.dart';

/// Put your real contact email here before publishing. It is shown in the
/// privacy policy screen.
const String kPrivacyContactEmail = 'tlhatmaher1893@gmail.com';
const String kPrivacyPolicyDate = '2026-11-24';

/// Shown at the top of the parent "account settings" tab:
///  - a warning while the parent PIN is still the factory default 123456
///  - a button that opens the in-app privacy policy
class SafetyPrivacyCard extends StatefulWidget {
  final AppStateManager appState;
  const SafetyPrivacyCard({super.key, required this.appState});

  @override
  State<SafetyPrivacyCard> createState() => _SafetyPrivacyCardState();
}

class _SafetyPrivacyCardState extends State<SafetyPrivacyCard> {
  bool _usesDefaultPin = false;

  @override
  void initState() {
    super.initState();
    _usesDefaultPin = _checkDefaultPin();
  }

  /// Checks without counting a failed attempt (verifyParentalPin would
  /// count one and could lock the gate).
  bool _checkDefaultPin() {
    final acc = widget.appState.currentAccount;
    if (acc == null) return false;
    try {
      return LocalCredentialSecurityService.verifySecret(
        inputSecret: '123456',
        storedHashOrLegacy: acc.pinHash,
        fallbackSalt: acc.pinSalt,
        accountEmail: acc.emailOrPhone,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usesDefaultPin)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFF7C2D12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFF59E0B), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'الرمز السري للوالدين ما زال هو الرمز الافتراضي 123456، '
                    'ويسهل على الطفل تخمينه. غيّره من خانة «الرمز السري» أدناه.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()),
          ),
          icon: Icon(Icons.privacy_tip_outlined),
          label: Text(tr('سياسة الخصوصية وحماية بيانات الأطفال')),
        ),
        SizedBox(height: 14),
      ],
    );
  }
}

/// Plain Arabic privacy policy, written from what the app actually does.
/// DRAFT: have it reviewed before publishing, and keep it in sync with the
/// Play Console "Data safety" form.
class PrivacyPolicyScreen extends StatelessWidget {
  PrivacyPolicyScreen({super.key});

  static List<List<String>> sections = [
    [
      'من نحن',
      tr('حنين كيدز تطبيق تعليمي للأطفال. هذه السياسة تشرح ما نحفظه وما لا نحفظه. التطبيق موجّه للأطفال، والوالدان هما المسؤولان عن الحساب.'),
    ],
    [
      'ما البيانات التي نحفظها',
      '• بيانات حساب ولي الأمر: الاسم، والبريد أو رقم الهاتف، وكلمة المرور والرمز السري '
          '(تُحفظ مشفّرة بصيغة هاش، ولا تُحفظ كنص ظاهر).\n'
          '• ملف الطفل: الاسم أو اللقب، والعمر، والصورة الرمزية، والنجوم والمستوى '
          'والدروس والألعاب المنجزة والمفردات التي تدرب عليها.\n'
          '• وقت الاستخدام اليومي وسجل النشاط ليراه ولي الأمر فقط.\n'
          'هذه البيانات تُحفظ على جهازك. وإذا فعّلت المزامنة السحابية تُرسل نسخة منها إلى خادم المزامنة الخاص بالتطبيق.',
    ],
    [
      'الصوت والميكروفون',
      'يستخدم نشاط «ردد معي» الميكروفون بعد إذن ولي الأمر فقط. التعرف على الكلام '
          'تنفذه خدمة التعرف على الكلام في جهازك (وقد يرسل جهاز أندرويد الصوت إلى خدمة جوجل لهذا الغرض). '
          'التطبيق لا يسجّل صوت الطفل ولا يحفظه ولا يرسله إلى خوادمنا.',
    ],
    [
      tr('الأصوات المنطوقة'),
      'معظم أصوات حنين مدمجة داخل التطبيق وتعمل دون إنترنت. عند عدم وجود تسجيل جاهز '
          'ومع وجود إنترنت، يُرسل نص الجملة فقط (قد يتضمن اسم الطفل) إلى خدمة توليد الصوت ElevenLabs '
          'لتحويله إلى كلام. لا يُرسل أي صوت ولا صور.',
    ],
    [
      'ما لا نفعله',
      '• لا إعلانات ولا تتبع إعلاني.\n'
          '• لا نبيع بيانات الأطفال ولا نشاركها لأغراض تسويقية.\n'
          '• لا روابط خارجية يمكن للطفل فتحها من داخل التطبيق.\n'
          '• لا نطلب من الطفل بيانات شخصية غير الاسم أو اللقب والعمر.',
    ],
    [
      'تنبيهات البريد لولي الأمر',
      tr('إذا فعّل ولي الأمر تنبيهات البريد، تُرسل ملخصات عن تقدم الطفل إلى بريد ولي الأمر.'),
    ],
    [
      tr('التحكم والحذف'),
      'يستطيع ولي الأمر في أي وقت: تغيير الرمز السري، وتعطيل الميكروفون والمزامنة، '
          'وحذف حساب ولي الأمر وبيانات الأطفال نهائياً من «إعدادات الحساب» داخل بوابة الوالدين.',
    ],
    [
      'التواصل',
      'لأي سؤال أو طلب حذف بيانات: {0}',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Tr.dir,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('سياسة الخصوصية'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('آخر تحديث: {0}', [kPrivacyPolicyDate]),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            for (final s in sections) ...[
              Text(s[0],
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(s[1], style: const TextStyle(fontSize: 14, height: 1.6)),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
