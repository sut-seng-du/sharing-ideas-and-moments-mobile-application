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
  String? _imagePath;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.message?.title ?? '');
    _contentController = TextEditingController(text: widget.message?.content ?? '');
    _imagePath = widget.message?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final path = fromCamera
        ? await _imageService.takePhoto()
        : await _imageService.pickImageFromGallery();
    
    if (path != null) {
      setState(() => _imagePath = path);
    }
  }

  Future<void> _saveMessage() async {
    if (_formKey.currentState!.validate()) {
      final message = Message(
        id: widget.message?.id,
        title: _titleController.text,
        content: _contentController.text,
        imagePath: _imagePath,
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
        title: Text(widget.message == null ? 'New Memory' : 'Edit Memory', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClayContainer(
              color: const Color(0xFF91A6FF),
              borderRadius: 12,
              depth: 4,
              spread: 2,
              child: IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _saveMessage,
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
              const SizedBox(height: 24),
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
              if (_imagePath != null)
                ClayContainer(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: 20,
                  depth: 10,
                  spread: 5,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_imagePath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 20, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
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
              Icon(icon, color: const Color(0xFF91A6FF), size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
