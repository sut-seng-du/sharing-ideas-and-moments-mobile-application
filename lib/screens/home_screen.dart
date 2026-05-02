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
  String? _selectedCategoryFilter;
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
        title: const Text('Delete Moments'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} moments?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE')),
        ],
      ),
    );

    if (confirmed == true) {
      final deletedItems = <Message>[];
      for (final id in _selectedIds) {
        final msg = await DatabaseHelper.instance.getMessage(id);
        if (msg != null) deletedItems.add(msg);
      }
      final deletedCount = _selectedIds.length;

      await DatabaseHelper.instance.deleteMultipleMessages(_selectedIds);
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: TweenAnimationBuilder<double>(
              tween: Tween(begin: 10.0, end: 0.0),
              duration: const Duration(seconds: 10),
              builder: (context, value, child) {
                final seconds = value.ceil();
                return Text(seconds <= 0 
                  ? '$deletedCount moment(s) deleted.' 
                  : '$deletedCount moment(s) deleted. Undo in ${seconds}s...');
              },
            ),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                for (final msg in deletedItems) {
                  await DatabaseHelper.instance.insertMessage(msg);
                }
                setState(() {});
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape ? 40 : 80,
        title: _isSelectionMode
            ? Text('${_selectedIds.length} selected')
            : (isLandscape
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8A41E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SIM',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0E608E),
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Sharing Ideas and Moments',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A8A8A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelected,
            )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isLandscape ? 80 : 140),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: isLandscape ? 4.0 : 8.0),
                child: ClayContainer(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: 20,
                  depth: 8,
                  spread: 4,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Search moments...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0E608E)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              FutureBuilder<List<String>>(
                future: DatabaseHelper.instance.getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final categories = ['All', ...snapshot.data!];
                  return SizedBox(
                    height: isLandscape ? 40 : 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isLandscape ? 4 : 8),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = (category == 'All' && _selectedCategoryFilter == null) ||
                            _selectedCategoryFilter == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryFilter = category == 'All' ? null : category;
                              });
                            },
                            child: ClayContainer(
                              color: isSelected ? const Color(0xFF0E608E) : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: 12,
                              depth: isSelected ? 2 : 4,
                              spread: 1,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Center(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Message>>(
        future: DatabaseHelper.instance.searchMessages(_searchQuery, category: _selectedCategoryFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bubble_chart_outlined, size: 80, color: const Color(0xFF0E608E).withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No moments yet...', style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final messages = snapshot.data!;
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

          if (isLandscape) {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.1,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessageCard(messages[index], context),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildMessageCard(messages[index], context),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClayContainer(
          color: const Color(0xFFF8A41E),
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

  Widget _buildMessageCard(Message message, BuildContext context) {
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
          ).then((result) {
            setState(() {});
            if (result != null && result is Map && result['action'] == 'deleted') {
              final deletedMessage = result['message'] as Message;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 10.0, end: 0.0),
                    duration: const Duration(seconds: 10),
                    builder: (context, value, child) {
                      final seconds = value.ceil();
                      return Text(seconds <= 0 
                        ? 'Moment deleted.' 
                        : 'Moment deleted. Undo in ${seconds}s...');
                    },
                  ),
                  duration: const Duration(seconds: 10),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () async {
                      await DatabaseHelper.instance.insertMessage(deletedMessage);
                      setState(() {});
                    },
                  ),
                ),
              );
            }
          });
        }
      },
      child: Hero(
        tag: 'msg_${message.id}',
        child: ClayContainer(
          color: isSelected ? const Color(0xFFDCE2EB) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: 30,
          depth: isSelected ? -8 : 12,
          spread: isSelected ? 2 : 6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                        color: const Color(0xFF0E608E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isUploaded) ...[
                            const Icon(Icons.check_circle, size: 10, color: Colors.green),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            DateFormat('MMM d').format(message.createdAt),
                            style: const TextStyle(color: Color(0xFF0E608E), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (message.category != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E608E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message.category!,
                      style: const TextStyle(
                        color: Color(0xFF91A6FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  message.content,
                  style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  MediaQuery.of(context).orientation == Orientation.landscape
                      ? Expanded(child: _buildImage(message))
                      : _buildImage(message, height: 160.0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Message message, {double height = double.infinity}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.file(
            File(message.imagePaths.first),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          ),
          if (message.imagePaths.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${message.imagePaths.length - 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
