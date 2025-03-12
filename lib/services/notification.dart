import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize local notifications
class NotificationService {
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'Channel Name',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }
}

// Subscribe to ntfy.sh notifications
void subscribeToNotification(String topic) async {
  print("🔔 Subscribing to topic: $topic");
  var url = Uri.parse('https://ntfy.sh/$topic/sse');

  try {
    var client = http.Client();
    var request = http.Request('GET', url);
    var response = await client.send(request);

    if (response.statusCode == 200) {
      print("✅ Connected to SSE stream...");

      response.stream
          .transform(utf8.decoder)
          .listen(
            (data) {
              try {
                var jsonData = jsonDecode(data.replaceFirst("data: ", ""));
                if (jsonData["event"] == "message") {
                  String message = jsonData["message"];
                  print("📩 New Notification: $message");

                  // Show local notification
                  NotificationService.showNotification("New Message", message);
                }
              } catch (e) {
                print("⚠️ Error parsing SSE event: $e");
              }
            },
            onError: (error) {
              print("❌ SSE Error: $error");
            },
            onDone: () {
              print("🔌 Connection closed.");
            },
          );
    } else {
      print("❌ Failed to subscribe: ${response.statusCode}");
    }
  } catch (e) {
    print("⚠️ Error subscribing to topic: $e");
  }
}

// Send a test notification to ntfy.sh
Future<void> sendNotification(String topic) async {
  var url = Uri.parse('https://ntfy.sh/$topic');
  print("📤 Sending notification to topic: $topic");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "text/plain; charset=utf-8"},
      body: utf8.encode("Hello from Flutter!"),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent successfully!");
    } else {
      print("❌ Failed to send notification: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  } catch (e) {
    print("⚠️ Error sending notification: $e");
  }
}
