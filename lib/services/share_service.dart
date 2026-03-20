import 'package:share_plus/share_plus.dart';
import '../models/message.dart';

class ShareService {
  static Future<void> shareMessage(Message message) async {
    if (message.imagePaths.isNotEmpty) {
      await Share.shareXFiles(
        message.imagePaths.map((path) => XFile(path)).toList(),
        text: '${message.title}\n\n${message.content}',
        subject: message.title,
      );
    } else {
      await Share.share(
        '${message.title}\n\n${message.content}',
        subject: message.title,
      );
    }
  }
}
