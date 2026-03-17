import 'package:flutter/material.dart';
import 'dart:io';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../services/image_service.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.message == null ? 'New Message' : 'Edit Message'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveMessage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const Divider(),
              TextFormField(
                controller: _contentController,
                maxLines: null,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: InputBorder.none,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 20),
              if (_imagePath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_imagePath!),
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _imagePath = null),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _MediaButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(false),
                  ),
                  const SizedBox(width: 12),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
