import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';

void main() {
  test('tr falls back to Arabic and fills placeholders', () {
    Tr.lang = 'ar';
    expect(tr('تقرير {0}', ['س']), 'تقرير س');
    Tr.lang = 'en';
    Tr.en = {'مرحبا {0}': 'Hello {0}'};
    expect(tr('مرحبا {0}', ['Sam']), 'Hello Sam');
    expect(tr('غير موجود'), 'غير موجود');
    Tr.lang = 'ar';
  });
}
