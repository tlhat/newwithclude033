import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Lets the parent save the family (child, stars, settings) to their own
/// Google Drive so it can be restored on a new phone.
class GoogleBackupCard extends StatefulWidget {
  final AppStateManager appState;
  const GoogleBackupCard({super.key, required this.appState});

  @override
  State<GoogleBackupCard> createState() => _GoogleBackupCardState();
}

class _GoogleBackupCardState extends State<GoogleBackupCard> {
  bool _busy = false;

  Future<void> _backup() async {
    setState(() => _busy = true);
    final String? err = await widget.appState.backupToGoogleNow();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? tr('تم حفظ نسخة احتياطية على حساب جوجل بتاعك.'))));
  }

  @override
  Widget build(BuildContext context) {
    final String? email = widget.appState.linkedGoogleEmail;
    return Card(
      child: ListTile(
        minVerticalPadding: 12,
        leading: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF3B82F6)),
        title: Text(tr('نسخة احتياطية على جوجل')),
        subtitle: Text(email == null
            ? tr('احفظ تقدم طفلك عشان ترجعه على أي موبايل جديد')
            : tr('مربوط بـ {0}', [email])),
        trailing: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(
                onPressed: _backup,
                child: Text(email == null ? tr('اربط واحفظ') : tr('احفظ الآن')),
              ),
        onLongPress: email == null
            ? null
            : () async {
                await widget.appState.unlinkGoogleBackup();
                if (mounted) setState(() {});
              },
      ),
    );
  }
}
