# Release prep checklist (before any store build)

- [ ] Remove the test unlock switch "فتح المحتوى المدفوع (تجريبي)" completely
      (Entitlements.setStubSubscribed and the SwitchListTile in
      regional_and_credits_card.dart). Removed, not hidden. Verify with a grep
      that no code path can set the subscribed flag without a real purchase.
- [ ] Real billing wired only with the owner's explicit OK.
- [ ] Signing key unchanged (SHA-1 starts 63a8843554).
- [ ] Credits for CC BY-SA sounds still visible in the parent corner.

## الأسعار
- أسعار الاشتراك مؤكدة من المستخدم (26 نوفمبر 2026): مصر 79 شهري / 199 كل 3 شهور / 599 سنوي / 999 عائلي سنوي (3 أطفال). التفاصيل بالدول في PLAY_RELEASE.md. لا يتم ربط فوترة قبل موافقته.
