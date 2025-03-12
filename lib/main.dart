import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:wesalvator/provider/themeprovider.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:wesalvator/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request notification permission when app starts
  await requestNotificationPermission();

  await storage.write(key: "BASE_URL", value: "https://wesalvator.com/api");
  await storage.write(
    key: "AUTH_BASE_URL",
    value: "https://wesalvator.com/api/accounts",
  );
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(camera: firstCamera),
    ),
  );
}

// Function to request notification permissions
Future<void> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();

  if (status.isGranted) {
    print("✅ Notification permission granted!");
  } else if (status.isDenied) {
    print("⚠️ Notification permission denied!");
  } else if (status.isPermanentlyDenied) {
    print("❌ Notification permission permanently denied! Opening settings...");
    openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'WeSalvatore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: SplashScreen(),
    );
  }
}
