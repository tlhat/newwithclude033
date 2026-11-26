import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/regional/country_config.dart';
import 'package:haneen_kids_vod/core/regional/regional_settings.dart';
import 'package:haneen_kids_vod/core/services/real_sounds_credits.dart';

/// Parent corner: country and dialect (auto or chosen), and the thanks list
/// for the real animal recordings.
class RegionalAndCreditsCard extends StatelessWidget {
  const RegionalAndCreditsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = RegionalSettings.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌍 الدولة واللهجة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'الدولة بتتحدد لوحدها من لغة الجهاز والشريحة، من غير GPS ومن غير ما يتبعت أي بيان. تقدر تغيّرها.',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Text('الدولة: '),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: s.countryIsAuto ? 'auto' : s.country.code,
                    items: [
                      DropdownMenuItem(
                          value: 'auto',
                          child: Text('تلقائي (${s.detectedCountry.nameAr})')),
                      for (final c in Countries.all)
                        DropdownMenuItem(value: c.code, child: Text(c.nameAr)),
                    ],
                    onChanged: (v) => s.setCountry(v == 'auto' ? null : v),
                  ),
                ),
              ]),
              Row(children: [
                const Text('اللهجة: '),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: s.dialectIsAuto ? 'auto' : s.dialect.key,
                    items: [
                      DropdownMenuItem(
                          value: 'auto',
                          child: Text('تلقائي (${s.dialect.nameAr})')),
                      for (final d in DialectId.values)
                        DropdownMenuItem(
                          value: d.key,
                          enabled: d.available,
                          child: Text(d.available
                              ? d.nameAr
                              : '${d.nameAr} (قريبًا)'),
                        ),
                    ],
                    onChanged: (v) => s.setDialect(
                        v == 'auto' ? null : DialectIdInfo.fromKey(v)),
                  ),
                ),
              ]),
              const Divider(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('🙏 شكر لأصوات الحيوانات الحقيقية',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                          'تسجيلات حرّة من ويكيميديا كومنز (CC0 أو ملكية عامة، وصوت الكلب والبقرة برخصة CC BY-SA مع نسب لأصحابهم). شكرًا لهم.',
                          style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                    ),
                  ),
                  for (final r in kRealSoundCredits)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${r[0]}: ${r[1]}'),
                      subtitle: Text('${r[2]} · ${r[3]}',
                          style: const TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
