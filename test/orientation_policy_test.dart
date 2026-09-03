import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/orientation_policy.dart';

/// Which way round each kind of window is allowed to be held.
void main() {
  late List<List<String>> asked;

  setUp(() {
    asked = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            asked.add(List<String>.from(call.arguments as List));
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: const OrientationPolicy(child: SizedBox()),
      ),
    );
  }

  // A phone is held upright whichever way it is turned — and a phone lying on
  // its side is still a phone, so the answer is the same either way round.
  for (final size in const [Size(390, 844), Size(844, 390), Size(360, 640)]) {
    testWidgets('a $size window is kept upright', (tester) async {
      await pumpAt(tester, size);
      expect(asked, [
        [DeviceOrientation.portraitUp.toString()],
      ]);
    });
  }

  // A tablet turns freely: the app states no preference of its own and leaves
  // the choice to the sensor, and on iOS to what the plist allows the iPad.
  for (final size in const [Size(834, 1194), Size(1194, 834), Size(768, 1024)]) {
    testWidgets('a $size window is left to turn', (tester) async {
      await pumpAt(tester, size);
      expect(asked, [<String>[]]);
    });
  }

  testWidgets('a foldable is measured as it is opened and shut', (
    tester,
  ) async {
    await pumpAt(tester, const Size(360, 844));
    await pumpAt(tester, const Size(760, 844));
    await pumpAt(tester, const Size(360, 844));

    expect(asked, [
      [DeviceOrientation.portraitUp.toString()],
      <String>[],
      [DeviceOrientation.portraitUp.toString()],
    ]);
  });

  testWidgets('a rebuild that changes nothing says nothing', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    await pumpAt(tester, const Size(390, 844));

    expect(asked, hasLength(1));
  });
}
