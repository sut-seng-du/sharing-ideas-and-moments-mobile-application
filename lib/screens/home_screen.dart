import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../widgets/clay_container.dart';
import 'message_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<int> _selectedIds = [];
  bool _isSelectionMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Messages'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} messages?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE')),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteMultipleMessages(_selectedIds);
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} selected')
            : const Text('Sharing Ideas and Moments', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelected,
            )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ClayContainer(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: 20,
              depth: 8,
              spread: 4,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search memories...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF91A6FF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Message>>(
        future: _searchQuery.isEmpty
            ? DatabaseHelper.instance.getAllMessages()
            : DatabaseHelper.instance.searchMessages(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bubble_chart_outlined, size: 80, color: const Color(0xFF91A6FF).withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No memories yet...', style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final messages = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isSelected = _selectedIds.contains(message.id);

              return GestureDetector(
                onLongPress: () => _toggleSelection(message.id!),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(message.id!);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(messageId: message.id!),
                      ),
                    ).then((_) => setState(() {}));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Hero(
                    tag: 'msg_${message.id}',
                    child: ClayContainer(
                      color: isSelected ? const Color(0xFFE0E5EC) : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: 30,
                      depth: isSelected ? 4 : 12,
                      spread: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    message.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4A4A4A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF91A6FF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    DateFormat('MMM d').format(message.createdAt),
                                    style: const TextStyle(color: Color(0xFF91A6FF), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message.content,
                              style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (message.imagePath != null) ...[
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(message.imagePath!),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClayContainer(
          color: const Color(0xFF91A6FF),
          borderRadius: 50,
          depth: 10,
          spread: 5,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessageScreen()),
              ).then((_) => setState(() {}));
            },
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
