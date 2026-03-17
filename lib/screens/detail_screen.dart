import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../services/share_service.dart';
import '../widgets/clay_container.dart';
import 'message_screen.dart';

class DetailScreen extends StatelessWidget {
  final int messageId;
  const DetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Message?>(
      future: DatabaseHelper.instance.getMessage(messageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Message not found')),
          );
        }

        final message = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              _ActionButton(
                icon: Icons.share,
                onPressed: () => ShareService.shareMessage(message),
              ),
              _ActionButton(
                icon: Icons.edit,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageScreen(message: message),
                    ),
                  ).then((_) => (context as Element).markNeedsBuild());
                },
              ),
              _ActionButton(
                icon: Icons.delete,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Message'),
                      content: const Text('Are you sure you want to delete this message?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await DatabaseHelper.instance.deleteMessage(messageId);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imagePath != null) ...[
                  Hero(
                    tag: 'msg_${message.id}',
                    child: ClayContainer(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: 30,
                      depth: 15,
                      spread: 7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.file(
                          File(message.imagePath!),
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                Text(
                  message.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF4A4A4A)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF91A6FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMMM d, yyyy • h:mm a').format(message.createdAt),
                    style: const TextStyle(color: Color(0xFF91A6FF), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                ClayContainer(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: 20,
                  depth: 5,
                  spread: 3,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message.content,
                    style: const TextStyle(fontSize: 17, height: 1.7, color: Color(0xFF4A4A4A)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: ClayContainer(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: 12,
        depth: 4,
        spread: 2,
        child: IconButton(
          icon: Icon(icon, color: const Color(0xFF4A4A4A), size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
