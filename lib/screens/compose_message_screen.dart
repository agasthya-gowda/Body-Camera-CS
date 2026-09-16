import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ComposeMessageScreen extends StatefulWidget {
  final Map<String, dynamic>? existingMessage;
  final String? webRoot;

  const ComposeMessageScreen({super.key, this.existingMessage, this.webRoot});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _existingImageUrl;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingMessage != null;



  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingMessage?['title'] ?? '');
    _contentController = TextEditingController(text: widget.existingMessage?['content'] ?? '');
    if (_isEditing) {
      _existingImageUrl = widget.existingMessage?['imgurl'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = image.name;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    Uint8List? imageBytesToSend = _pickedImageBytes;
    String? imageNameToSend = _pickedImageName;

    if (imageBytesToSend == null && _isEditing && _existingImageUrl != null) {
      try {
        final imageBaseUrl = widget.webRoot ?? ApiService.baseUrl;
        final imageUrl = imageBaseUrl + _existingImageUrl!;
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytesToSend = response.bodyBytes;
          imageNameToSend = _existingImageUrl!.split('/').last;
        }
      } catch (e) {
        // fall through to error below if this fails
      }
    }

    if (imageBytesToSend == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image (required)')),
        );
      }
      return;
    }

    Map<String, dynamic> result;
    if (_isEditing) {
      result = await _apiService.modifyMessage(
        messId: widget.existingMessage!['id'].toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageBytes: imageBytesToSend,
        imageFileName: imageNameToSend!,
      );
    } else {
      result = await _apiService.createMessage(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageBytes: imageBytesToSend,
        imageFileName: imageNameToSend!,
      );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      final newMessageId = result['data']?['id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Message updated' : 'Message created (ID: $newMessageId)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteMessage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(height: 12),
              const Text('Delete Message?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('This dispatch template will be permanently removed.',
                  style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final result = await _apiService.deleteMessage(widget.existingMessage!['id'].toString());
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['msg'] ?? 'Deleted'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF020617),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  _HoverIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEditing ? 'Edit Dispatch' : 'Compose Dispatch',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('Tactical Broadcast Advisory', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (_isEditing) _HoverDeleteButton(onTap: _isSubmitting ? () {} : _deleteMessage),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Title', required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Advisory Message Content', required: true),
                      maxLines: 5,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: _pickedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : (_isEditing && _existingImageUrl != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          (widget.webRoot ?? ApiService.baseUrl) + _existingImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Tap to change',
                                                style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 36, color: Colors.white24),
                                        SizedBox(height: 8),
                                        Text('Tap to select image *', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitForm,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : (_isEditing ? 'UPDATE DISPATCH TEMPLATE' : 'PROCEED TO SELECT RECIPIENTS'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          shadowColor: Colors.purple.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoverIconButton({required this.icon, required this.onTap});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF334155) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Icon(widget.icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class _HoverDeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverDeleteButton({required this.onTap});

  @override
  State<_HoverDeleteButton> createState() => _HoverDeleteButtonState();
}

class _HoverDeleteButtonState extends State<_HoverDeleteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.redAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              SizedBox(width: 4),
              Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}