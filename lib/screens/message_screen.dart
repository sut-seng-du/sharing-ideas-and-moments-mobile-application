import 'package:flutter/material.dart';
import 'dart:io';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../services/image_service.dart';
import '../widgets/clay_container.dart';

class MessageScreen extends StatefulWidget {
  final Message? message;
  const MessageScreen({super.key, this.message});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String> _imagePaths = [];
  String? _selectedCategory;
  final ImageService _imageService = ImageService();

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.message?.title ?? '');
    _contentController = TextEditingController(text: widget.message?.content ?? '');
    _imagePaths = List<String>.from(widget.message?.imagePaths ?? []);
    _selectedCategory = widget.message?.category;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategories();
    setState(() => _categories = categories);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    if (_imagePaths.length >= 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('X supports only up to 4 photos per moment.')),
        );
      }
      return;
    }

    if (fromCamera) {
      final path = await _imageService.takePhoto();
      if (path != null) {
        setState(() => _imagePaths.add(path));
      }
    } else {
      final paths = await _imageService.pickMultiImage();
      if (paths.isNotEmpty) {
        setState(() {
          final remaining = 4 - _imagePaths.length;
          if (paths.length > remaining) {
            _imagePaths.addAll(paths.take(remaining));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $remaining photos. X limit is 4 photos per moment.')),
              );
            }
          } else {
            _imagePaths.addAll(paths);
          }
        });
      }
    }
  }

  Future<void> _addNewCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category Name (e.g. Travel)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await DatabaseHelper.instance.insertCategory(name);
      await _loadCategories();
      setState(() => _selectedCategory = name);
    }
  }

  Future<void> _saveMessage() async {
    if (_formKey.currentState!.validate()) {
      final message = Message(
        id: widget.message?.id,
        title: _titleController.text,
        content: _contentController.text,
        imagePaths: _imagePaths,
        category: _selectedCategory,
        createdAt: widget.message?.createdAt ?? DateTime.now(),
      );

      if (widget.message == null) {
        await DatabaseHelper.instance.insertMessage(message);
      } else {
        await DatabaseHelper.instance.updateMessage(message);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.message == null ? 'New Moments' : 'Edit Moments', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _saveMessage,
              behavior: HitTestBehavior.opaque,
              child: ClayContainer(
                color: const Color(0xFF0E608E),
                borderRadius: 12,
                depth: 4,
                spread: 2,
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayContainer(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: 20,
                depth: 8,
                spread: 4,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: _addNewCategory,
                          child: ClayContainer(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: 15,
                            depth: 6,
                            spread: 3,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: const Icon(Icons.add, size: 20, color: Color(0xFF0E608E)),
                          ),
                        ),
                      ),
                      ..._categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = isSelected ? null : category;
                              });
                            },
                            child: ClayContainer(
                              color: isSelected ? const Color(0xFF0E608E) : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: 15,
                              depth: isSelected ? 2 : 6,
                              spread: 3,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClayContainer(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: 20,
                depth: 8,
                spread: 4,
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A), height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    border: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Content is required' : null,
                ),
              ),
              const SizedBox(height: 24),
              if (_imagePaths.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 20,
                          depth: 8,
                          spread: 4,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(_imagePaths[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () => setState(() => _imagePaths.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _MediaButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(false),
                  ),
                  const SizedBox(width: 20),
                  _MediaButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClayContainer(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: 20,
          depth: 10,
          spread: 5,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0E608E), size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
