import 'dart:developer';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static Future<void> sendFeedbackEmail({
    required String name,
    required String email,
    required String description,
    required List<File> images,
  }) async {
    final String username = "happyonlyindreams@gmail.com"; // Your Gmail
    final String password = "njcbakzujnfcvlggq"; // Yourn App Password

    final smtpServer = gmail(username, password);

    final message =
        Message()
          ..from = Address(username, "Feedback")
          ..recipients.add("mail@wesalvator.com")
          ..subject = "New Feedback from $name"
          ..text = '''
Name: $name
Email: $email
Description: $description
''';

    // Attach images safely
    for (File image in images) {
      if (image.existsSync()) {
        message.attachments.add(
          FileAttachment(image)..contentType = 'image/jpeg',
        );
      } else {
        log("Warning: Image file not found - ${image.path}");
      }
    }

    try {
      log("Attempting to send email...");
      final sendReport = await send(message, smtpServer);
      log("Email sent successfully! Report: $sendReport");
    } on SmtpClientAuthenticationException {
      log("Error: Authentication failed! Check email/password.");
    } on SocketException {
      log("Error: No internet connection.");
    } catch (e) {
      log("Failed to send email: $e");
    }
  }
}
