import 'dart:convert';
import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize local notifications
class NotificationService {
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      'ws_logo',
    ); // Use @mipmap instead of @drawable

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id', // Channel ID
          'Channel Name', // Channel Name
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          // Add this line
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Title
      body, // Body
      platformDetails, // Platform-specific details
      payload: jsonEncode({
        'title': title,
        'body': body,
      }), // Add a meaningful payload
    );
  }
}

// Subscribe to ntfy.sh notifications
void subscribeToNotification(String topic) async {
  log("Subscribing to topic: $topic");
  var url = Uri.parse('https://ntfy.sh/$topic/sse');

  try {
    var client = http.Client();
    var request = http.Request('GET', url);
    var response = await client.send(request);

    if (response.statusCode == 200) {
      log("Connected to SSE stream...");

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter()) // Split the stream into lines
          .listen(
            (data) {
              if (data.startsWith("data: ")) {
                try {
                  var jsonData = jsonDecode(
                    data.substring(6),
                  ); // Remove "data: " prefix
                  if (jsonData["event"] == "message") {
                    String message = jsonData["message"];
                    log("New Notification: $message");

                    // Show local notification
                    NotificationService.showNotification(
                      "New Message",
                      message,
                    );
                  }
                } catch (e) {
                  log("Error parsing SSE event: $e");
                }
              }
            },
            onError: (error) {
              log("SSE Error: $error");
              // Retry logic or reconnect logic can be added here
            },
            onDone: () {
              log("Connection closed.");
              // Retry logic or reconnect logic can be added here
            },
          );
    } else {
      log("Failed to subscribe: ${response.statusCode}");
    }
  } catch (e) {
    log("Error subscribing to topic: $e");
  }
}

// Send a test notification to ntfy.sh
Future<void> sendNotification(String topic) async {
  var url = Uri.parse('https://ntfy.sh/$topic');
  log("Sending notification to topic: $topic");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "text/plain; charset=utf-8"},
      body: utf8.encode("Hello from Flutter!"),
    );

    if (response.statusCode == 200) {
      log("Notification sent successfully!");
    } else {
      log("Failed to send notification: ${response.statusCode}");
      log("Response: ${response.body}");
    }
  } catch (e) {
    log("Error sending notification: $e");
  }
}
