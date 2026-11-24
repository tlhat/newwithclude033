import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/services/local_audio_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('key ignores quotes, label emoji and extra spaces', () {
    expect(LocalAudioLibrary.keyFor('haneen', '«أَسَد»   شجاع'),
        LocalAudioLibrary.keyFor('haneen', 'أَسَد شجاع'));
  });

  test('key is stable and matches the python index builder', () {
    // Computed with tools/build_audio_index.py: sha1("haneen|مرحبا بطل")[:12]
    expect(LocalAudioLibrary.keyFor('haneen', 'مرحبا بطل'), 'a822892cb8fe');
  });

  test('missing index means no local clip', () async {
    LocalAudioLibrary.setIndexForTesting({});
    expect(await LocalAudioLibrary.resolveToFile('haneen', 'x'), isNull);
  });

  test('resolves a bundled clip to a real file, also via alternate text',
      () async {
    final String key = LocalAudioLibrary.keyFor('haneen', 'أهلاً بك يا بطل');
    LocalAudioLibrary.setIndexForTesting({key: 'assets/audio/haneen/x/a.mp3'});
    final Uint8List fake = Uint8List.fromList(List<int>.generate(64, (i) => i));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? msg) async {
      final String name = utf8.decode(msg!.buffer.asUint8List());
      if (name == 'assets/audio/haneen/x/a.mp3') {
        return ByteData.sublistView(fake);
      }
      return null;
    });
    final String? path = await LocalAudioLibrary.resolveToFile(
      'haneen',
      'أهلاً بك يا سلمى',
      alternateTexts: ['أهلاً بك يا بطل'],
    );
    expect(path, isNotNull);
    expect(await File(path!).readAsBytes(), fake);
    // Another persona still finds the recorded line.
    expect(
        await LocalAudioLibrary.resolveToFile('storyteller', 'أهلاً بك يا بطل'),
        isNotNull);
    expect(
        await LocalAudioLibrary.resolveToFile('storyteller', 'سطر غير موجود'),
        isNull);
  });
}
