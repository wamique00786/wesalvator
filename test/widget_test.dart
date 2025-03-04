import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:wesalvator/main.dart';
import 'package:wesalvator/provider/themeprovider.dart';

void main() {
  // Mock camera description
  final CameraDescription mockCamera = CameraDescription(
    name: 'mock',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 0,
  );

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Wrap MyApp with the required Provider(s)
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(), // Provide the ThemeProvider
        child: MyApp(camera: mockCamera),
      ),
    );

    // Verify that the counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byType(IconButton));
    await tester
        .pump(); // or await tester.pumpAndSettle() if there are animations

    // Verify that the counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
