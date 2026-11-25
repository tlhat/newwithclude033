import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/data/models/parent_account_model.dart';

void main() {
  test('email alert is not marked delivered unless a webhook confirmed it', () {
    final a = ParentEmailAlertItem(
        id: '1', recipientEmail: 'a@b.c', subject: 's', bodyMessage: 'b',
        smartImprovementSuggestion: '', sentAt: DateTime(2026));
    expect(a.deliveredToCloud, false);
    expect(ParentEmailAlertItem.fromJson({'id': '2'}).deliveredToCloud, false);
    expect(ParentEmailAlertItem.fromJson({'id': '3', 'deliveredToCloud': true}).deliveredToCloud, true);
  });
}
