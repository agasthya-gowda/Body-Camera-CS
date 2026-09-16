import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';

class AddOfficerScreen extends StatefulWidget {
  final Map<String, dynamic> userTypes;

  const AddOfficerScreen({super.key, required this.userTypes});

  @override
  State<AddOfficerScreen> createState() => _AddOfficerScreenState();
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
    final isDark = AppTheme.isDark(context);
    final hoverColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? Colors.white : const Color(0xFF0A1628);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : borderColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Icon(widget.icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}

class _AddOfficerScreenState extends State<AddOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _hostcodeController = TextEditingController();
  final _realnameController = TextEditingController();
  final _bhController = TextEditingController();
  final _mobileController = TextEditingController();
  final _telController = TextEditingController();
  final _sortController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedType;
  bool _isSubmitting = false;

  bool get _isDark => AppTheme.isDark(context);

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _apiService.registerUser(
      hostcode: _hostcodeController.text.trim(),
      realname: _realnameController.text.trim(),
      bh: _bhController.text.trim(),
      type: _selectedType ?? '',
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      tel: _telController.text.trim().isEmpty ? null : _telController.text.trim(),
      sort: _sortController.text.trim().isEmpty ? null : _sortController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      final newUserId = result['data']?['id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Officer registered successfully (ID: $newUserId)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, newUserId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _hostcodeController.dispose();
    _realnameController.dispose();
    _bhController.dispose();
    _mobileController.dispose();
    _telController.dispose();
    _sortController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon, {bool required = false}) {
    final borderColor = _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(color: _isDark ? Colors.white54 : Colors.grey[700], fontSize: 12),
      prefixIcon: Icon(icon, color: _isDark ? Colors.white38 : Colors.grey[500], size: 18),
      filled: true,
      fillColor: _isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9);
    final surfaceColor = _isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final primaryTextColor = _isDark ? Colors.white : const Color(0xFF0A1628);
    final mutedTextColor = _isDark ? Colors.white38 : Colors.grey[500];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  _HoverIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Officer',
                          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Personnel Enrollment (Multipart Form)',
                          style: TextStyle(color: mutedTextColor, fontSize: 11)),
                    ],
                  ),
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
                      controller: _hostcodeController,
                      style: TextStyle(color: primaryTextColor, fontSize: 13),
                      decoration: _fieldDecoration('Badge / Hostcode', Icons.tag, required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _realnameController,
                      style: TextStyle(color: primaryTextColor, fontSize: 13),
                      decoration: _fieldDecoration('Full Name (realname)', Icons.person_outline, required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bhController,
                      style: TextStyle(color: primaryTextColor, fontSize: 13),
                      decoration: _fieldDecoration('Unit Name (bh)', Icons.apartment, required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      dropdownColor: surfaceColor,
                      style: TextStyle(color: primaryTextColor, fontSize: 13),
                      decoration: _fieldDecoration('Police Rank (type)', Icons.shield_outlined, required: true),
                      items: widget.userTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toString())))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedType = value),
                      validator: (value) => (value == null) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            style: TextStyle(color: primaryTextColor, fontSize: 13),
                            decoration: _fieldDecoration('Mobile (optional)', Icons.phone_iphone),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _telController,
                            style: TextStyle(color: primaryTextColor, fontSize: 13),
                            decoration: _fieldDecoration('Tel (optional)', Icons.call),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _sortController,
                      style: TextStyle(color: primaryTextColor, fontSize: 13),
                      decoration: _fieldDecoration('Display Sort Order', Icons.sort),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: primaryTextColor, fontSize: 13),
                      decoration: _fieldDecoration('Officer Notes (optional)', Icons.notes),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitForm,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSubmitting ? 'Submitting Registration...' : 'ENROLL OFFICER TO DEPARTMENT',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          shadowColor: Colors.green.withOpacity(0.4),
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