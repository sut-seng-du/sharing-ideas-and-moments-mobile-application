import 'package:share_plus/share_plus.dart';
import '../models/message.dart';

class ShareService {
  static Future<void> shareMessage(Message message) async {
    final String text = '${message.title}\n\n${message.content}';
    
    if (message.imagePath != null && message.imagePath!.isNotEmpty) {
      await Share.shareXFiles(
        [XFile(message.imagePath!)],
        text: text,
      );
    } else {
      await Share.share(text);
    }
  }
}
