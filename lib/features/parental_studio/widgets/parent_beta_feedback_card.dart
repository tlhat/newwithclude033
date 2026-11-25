import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Parent-Only Beta Feedback, Version/Environment Info & Feature Flags Card
/// (Stage P0 / Sprint 4: strictly inside Parental Studio, zero child PII collected).
class ParentBetaFeedbackCard extends StatefulWidget {
  final AppStateManager appState;

  ParentBetaFeedbackCard({
    super.key,
    required this.appState,
  });

  @override
  State<ParentBetaFeedbackCard> createState() => _ParentBetaFeedbackCardState();
}

class _ParentBetaFeedbackCardState extends State<ParentBetaFeedbackCard> {
  final TextEditingController _notesCtrl = TextEditingController();
  String _selectedCategory = 'مشكلة استخدام';

  static List<String> _categories = [
    'عطل حرج',
    'مشكلة استخدام',
    'ترجمة',
    'محتوى',
    'اقتراح',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final env = widget.appState.environmentConfig;
    final flags = widget.appState.featureFlags;
    if (!flags.enableParentFeedbackForm) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppDesignTokens.primaryPurple.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report_rounded,
                      color: AppDesignTokens.infoBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'معلومات النسخة وملاحظات ولي الأمر (تجريبية)',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'الإصدار والبيئة: ${env.buildInfoSummary}',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF0F172A),
                decoration: InputDecoration(
                  labelText: 'تصنيف الملاحظة',
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة أو الاقتراح (بدون بيانات شخصية للطفل)',
                  hintText: 'اكتب الخطوات أو الشاشة التي ظهرت فيها الملاحظة...',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final String text = _notesCtrl.text.trim();
                    if (text.isEmpty) return;
                    await widget.appState.submitParentBetaFeedback(
                      category: _selectedCategory,
                      description: text,
                    );
                    _notesCtrl.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ تم تسجيل ملاحظتك بنجاح في سجل الدعم.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: Text('إرسال الملاحظة لفريق التطوير'),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'تفعيل تلميحات التعلم التكيفي التجريبية',
                  style: TextStyle(fontSize: 13.5, color: Colors.white),
                ),
                value: flags.enableExperimentalAdaptiveHints,
                onChanged: (val) =>
                    widget.appState.setFeatureFlag('adaptive_hints', val),
              ),

              if (widget.appState.betaFeedbackLog.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'سجل الملاحظات المرسلة للمطورين:',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...widget.appState.betaFeedbackLog.take(4).map((entry) {
                  final String status = entry['status'] ?? 'Pending';
                  Color statusColor = const Color(0xFFF59E0B);
                  String statusLabel = 'قيد الانتظار';
                  if (status == 'Sent') {
                    statusColor = const Color(0xFF10B981);
                    statusLabel = 'تم الإرسال';
                  } else if (status == 'Failed') {
                    statusColor = const Color(0xFFEF4444);
                    statusLabel = 'فشل الإرسال';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry['category'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (status == 'Failed' || status == 'Pending') ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => widget.appState
                                  .retrySendingBetaFeedback(entry['id'] ?? ''),
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: Text(
                                'إعادة المحاولة',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
