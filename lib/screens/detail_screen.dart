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
            body: const Center(child: Text('Moment not found')),
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
                      title: const Text('Delete Moment'),
                      content: const Text('Are you sure you want to delete this moment?'),
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
                if (message.imagePaths.isNotEmpty) ...[
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.imagePaths.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Hero(
                            tag: index == 0 ? 'msg_${message.id}' : 'msg_${message.id}_$index',
                            child: ClayContainer(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: 30,
                              depth: 15,
                              spread: 7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.file(
                                  File(message.imagePaths[index]),
                                  width: MediaQuery.of(context).size.width - 80,
                                  height: 300,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                Text(
                  message.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF4A4A4A)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4), // Extra vertical space for shadows
                    child: Row(
                      children: [
                        ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 12,
                          depth: 6, // Increased depth for better 3d
                          spread: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF91A6FF)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(message.createdAt),
                                style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (message.category != null) ...[
                          const SizedBox(width: 24),
                          ClayContainer(
                            color: const Color(0xFF91A6FF),
                            borderRadius: 12,
                            depth: 6, // Increased depth for better 3d
                            spread: 3,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Text(
                              message.category!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
