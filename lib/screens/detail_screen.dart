import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../services/share_service.dart';
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
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: message.imagePath != null ? 300 : 0,
                pinned: true,
                flexibleSpace: message.imagePath != null
                    ? FlexibleSpaceBar(
                        background: Hero(
                          tag: 'msg_${message.id}',
                          child: Image.file(
                            File(message.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : null,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => ShareService.shareMessage(message),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageScreen(message: message),
                        ),
                      ).then((_) => (context as Element).markNeedsBuild());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
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
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      message.title,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posted on ${DateFormat('MMMM d, yyyy • h:mm a').format(message.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message.content,
                      style: const TextStyle(fontSize: 18, height: 1.6, color: Color(0xFF2D3748)),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
