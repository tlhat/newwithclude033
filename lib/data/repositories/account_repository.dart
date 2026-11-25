import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class AccountRepository {
  final LocalAccountDataSource dataSource;
  final SupabaseRemoteDataSource? remoteDataSource;
  final OfflineSyncQueueService? syncQueue;

  const AccountRepository(
    this.dataSource, {
    this.remoteDataSource,
    this.syncQueue,
  });

  Map<String, ParentAccount> loadAllAccounts() =>
      dataSource.loadRegisteredAccounts();

  Future<void> persistAllAccounts(Map<String, ParentAccount> accounts) =>
      dataSource.saveRegisteredAccounts(accounts);

  Future<void> enqueueAccountSync(ParentAccount account) async {
    if (syncQueue == null) return;
    if (account.authProvider == 'demo' || account.emailOrPhone == 'parent@haneenkids.com') {
      // Isolate demo accounts locally: never sync demo mock credentials to Supabase
      return;
    }
    final String email = account.emailOrPhone.trim().toLowerCase();
    await syncQueue!.enqueueMutation(
      SyncMutationRecord(
        idempotencyKey: 'acc_upsert_$email',
        parentEmail: email,
        entityType: 'parent_account',
        entityId: email,
        operation: 'upsert',
        payload: {
          'accountUid': account.accountUid,
          'emailOrPhone': email,
          'phoneE164': AuthSessionService.isPhoneNumberIdentifier(email) ? email : null,
          'registeredClientIpHash': account.registeredClientIpHash,
          'fullName': account.fullName,
          'authProvider': account.authProvider,
          'subscriptionPlanId': account.subscriptionPlanId,
          'trialStartDate': account.trialStartDate.toIso8601String(),
          'subscriptionExpiryDate': account.subscriptionExpiryDate.toIso8601String(),
          'warmEveningFilter': account.warmEveningFilter,
          'emailNotificationsEnabled': account.emailNotificationsEnabled,
          'dailySmartSuggestionsEnabled': account.dailySmartSuggestionsEnabled,
          'voiceAssistantEnabled': account.voiceAssistantEnabled,
          'activeChildId': account.activeChildId,
        },
      ),
    );
  }

  Future<void> deleteAccountOnServerAndQueue({
    required String parentEmail,
    required String sessionAccessToken,
  }) async {
    if (syncQueue != null) {
      await syncQueue!.clearAllForParent(parentEmail);
    }
    if (remoteDataSource != null) {
      await remoteDataSource!.invokeServerRpc(
        rpcName: 'rpc_delete_parent_account_cascade',
        sessionAccessToken: sessionAccessToken,
      );
    }
  }

  ParentAccount buildDefaultDemoAccount() {
    final demoAccount = ParentAccount(
      fullName: 'أبو فارس (حساب تجريبي)',
      emailOrPhone: 'parent@haneenkids.com',
      password: '123456',
      parentalPin: '123456',
      authProvider: 'demo',
      warmEveningFilter: false,
      subscriptionPlanId: 'trial_1day',
      trialStartDate: DateTime.now(),
      subscriptionExpiryDate: DateTime.now().add(const Duration(hours: 24)),
      children: [
        ChildProfile(
          id: 'child_faris',
          name: 'فارس',
          age: '3–6 سنوات',
          dailyTimeLimit: 20,
          starsEarned: 4,
          chosenAvatar: '🦁',
          usedMinutesToday: 0,
          watchedVideosToday: 1,
          correctPronunciationsCount: 2,
        ),
        ChildProfile(
          id: 'child_noor',
          name: 'نور',
          age: '4–8 سنوات',
          dailyTimeLimit: 25,
          starsEarned: 6,
          chosenAvatar: '🦋',
          usedMinutesToday: 0,
          watchedVideosToday: 2,
          correctPronunciationsCount: 3,
        ),
      ],
      activeChildId: 'child_faris',
    );
    demoAccount.emailAlertsLog.add(
      ParentEmailAlertItem(
        id: 'alert_welcome',
        recipientEmail: 'parent@haneenkids.com',
        subject:
            '🎉 مرحباً بك في حنين كيدز — التطبيق مجاني بالكامل ١٠٠٪',
        bodyMessage:
            'تم تفعيل حسابك بنجاح مجاناً بالكامل دون أي اشتراكات أو إعلانات. يمكنك متابعة تقدم فارس ونور في الفصاحة والأنشطة الواقعية من بوابة الوالدين.',
        smartImprovementSuggestion:
            '💡 اقتراح لتحسين التجربة: فعّل «فلتر المساء الدافئ» قبل موعد نوم الطفل بنصف ساعة.',
        sentAt: DateTime.now(),
      ),
    );
    return demoAccount;
  }
}
