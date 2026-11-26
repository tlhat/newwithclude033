import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class MultiChildProfilesScreen extends StatefulWidget {
  final AppStateManager appState;
  const MultiChildProfilesScreen({super.key, required this.appState});

  @override
  State<MultiChildProfilesScreen> createState() =>
      _MultiChildProfilesScreenState();
}

class _MultiChildProfilesScreenState extends State<MultiChildProfilesScreen> {
  final List<String> _ageGroups = [
    '1–2 سنة',
    '2–4 سنوات',
    '3–6 سنوات',
    '4–8 سنوات',
    '6–10 سنوات'
  ];
  final List<String> _avatars = [
    '🦁',
    '🦋',
    '🐰',
    '🐼',
    '🚀',
    '🌸',
    '🐬',
    '🦊',
    '🐯',
    '🦄'
  ];

  void _showAddChildDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController addPinCtrl = TextEditingController();
    String? addChildError;
    String selectedAge = '3–6 سنوات';
    String selectedAvatar = '🦁';
    String selectedGender = 'boy';
    int selectedMinutes = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                right: 24,
                left: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '➕ إضافة ملف طفل جديد (بموافقة ولي الأمر)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم الطفل',
                        hintText: 'مثال: سارة أو عمر',
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'الجنس:',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          avatar: const Text('👦'),
                          label: Text('ولد'),
                          selected: selectedGender == 'boy',
                          selectedColor:
                              const Color(0xFF6C63FF).withOpacity(0.35),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedGender = 'boy');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Text('👧'),
                          label: Text('بنت'),
                          selected: selectedGender == 'girl',
                          selectedColor:
                              const Color(0xFFFF7892).withOpacity(0.35),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedGender = 'girl');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedAge,
                      decoration: InputDecoration(
                        labelText: 'الفئة العمرية',
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
                          setModalState(() => selectedAge = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'اختر الرمز التعبيري :',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _avatars.map((emoji) {
                        final isSelected = selectedAvatar == emoji;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedAvatar = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF14B8A6).withOpacity(0.3)
                                  : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF14B8A6)
                                    : Colors.white12,
                                width: 2,
                              ),
                            ),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'دقائق المشاهدة اليومية:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${selectedMinutes} دقيقة / يومياً',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: selectedMinutes.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      activeColor: const Color(0xFF14B8A6),
                      onChanged: (val) =>
                          setModalState(() => selectedMinutes = val.round()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'رمز PIN الأبوي (٦ أرقام) لتأكيد إضافة الملف',
                        counterText: '',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (addChildError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        addChildError!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) {
                            setModalState(() {
                              addChildError = 'يرجى إدخال اسم الطفل أولاً.';
                            });
                            return;
                          }
                          final acc = widget.appState.currentAccount;
                          if (acc != null && !acc.isGuestDemoSession) {
                            if (acc.isPinLockedOut) {
                              setModalState(() {
                                addChildError =
                                    '⏳ تم قفل الرمز الأبوي مؤقتاً. انتظر ${acc.remainingPinLockoutSeconds} ثانية.';
                              });
                              return;
                            }
                            if (!acc.verifyParentalPin(addPinCtrl.text)) {
                              setModalState(() {
                                addChildError =
                                    'رمز PIN الأبوي غير صحيح؛ لا يمكن إضافة ملف طفل بدون موافقة ولي الأمر.';
                              });
                              return;
                            }
                          }
                          widget.appState.addChildProfile(
                            name: nameCtrl.text,
                            age: selectedAge,
                            chosenAvatar: selectedAvatar,
                            dailyTimeLimit: selectedMinutes,
                            gender: selectedGender,
                          );
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          'حفظ ملف الطفل',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.appState.currentAccount;
    if (account == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        leading: account.isGuestDemoSession
            ? IconButton(
                tooltip: 'الرجوع لصفحة البداية وتسجيل الدخول',
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFFF59E0B)),
                onPressed: () => widget.appState.logout(),
              )
            : null,
        title: Text(
          'من سيشاهد قصص حنين اليوم؟',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                widget.appState.selectChildAndEnterFeed(account.activeChildId),
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF14B8A6)),
            label: Text(
              'المشغل',
              style: TextStyle(
                  color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmoothFreeTrialStatusBanner(account: account),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'رأيك يفرق معانا. قيّم حنين كيدز ⭐',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'مرحباً بك يا ${account.fullName} 👋 اختر ملف الطفل للبدء أو أضف طفلاً جديداً:',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: account.children.length + 1,
                    itemBuilder: (context, index) {
                      if (index == account.children.length) {
                        return GestureDetector(
                          onTap: _showAddChildDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF14B8A6).withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Color(0xFF14B8A6),
                                  child: Icon(Icons.add,
                                      size: 34, color: Colors.white),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'إضافة طفل جديد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'تخصيص العمر والوقت',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final child = account.children[index];
                      final isSelected = child.id == account.activeChildId;
                      return GestureDetector(
                        onTap: () =>
                            widget.appState.selectChildAndEnterFeed(child.id),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF14B8A6).withOpacity(0.18)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF14B8A6)
                                  : Colors.white12,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                child.chosenAvatar,
                                style: const TextStyle(fontSize: 50),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                child.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                child.age,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '⏱️ ${child.usedMinutesToday}/${child.limitShown} د • ⭐ ${child.starsEarned}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
