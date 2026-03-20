import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../services/share_service.dart';
import '../services/twitter_service.dart';
import '../widgets/clay_container.dart';
import 'message_screen.dart';

class DetailScreen extends StatelessWidget {
  final int messageId;
  const DetailScreen({super.key, required this.messageId});

  Future<void> _handleTwitterUpload(BuildContext context, Message message) async {
    try {
      if (!await TwitterService.isConnected()) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('X Authentication'),
            content: const Text('You need to log in to X to auto-upload. Would you like to log in now?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOG IN')),
            ],
          ),
        );
        
        if (proceed != true) return;

        // Show loading during authentication
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        await TwitterService.authenticate();
        
        // Check connection again
        if (!await TwitterService.isConnected()) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication failed or was cancelled.')),
            );
          }
          return;
        }

        // If authenticated, we continue below to post the message
      } else {
        // Show loading if already connected
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }
      }

      await TwitterService.postMessage(message);

      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully posted to X!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
                icon: Icons.rocket_launch, // Using rocket as a placeholder for "X" speed/auto-upload
                onPressed: () => _handleTwitterUpload(context, message),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF0E608E),
                    letterSpacing: -0.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 12,
                          depth: 4,
                          spread: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Color(0xFF0E608E)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(message.createdAt),
                                style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (message.category != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E608E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.category!,
                              style: const TextStyle(
                                color: Color(0xFF0E608E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message.content,
                  style: const TextStyle(
                    fontSize: 17, 
                    height: 1.6, 
                    color: Color(0xFF4A4A4A), 
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (message.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 40),
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
                              depth: 12,
                              spread: 6,
                              border: Border.all(color: const Color(0xFF0E608E), width: 1.5),
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
                ],
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
