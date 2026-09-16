import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import '../widgets/responsive_content.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  List<String> _messTypes = [];
  String? _webRoot;
  bool _isLoading = true;
  Timer? _debounceTimer;

  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final keyword = _searchController.text.trim();
    final result = await _apiService.searchMessages(
      keyword: keyword.isEmpty ? null : keyword,
    );
    if (result['code'] == 200) {
      final data = result['data'];
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data['list'] ?? []);
        // Real server returns messtype as a list of category names, indexed
        // by the numeric "type" field on each message (not a map).
        _messTypes = List<String>.from(data['messtype'] ?? []);
        _webRoot = data['web_root'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: ${result['msg']}')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Template',
          style: TextStyle(
            color: _isDark ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
        content: Text(
          'Delete "${message['title'] ?? 'this message'}"? This cannot be undone.',
          style: TextStyle(color: _isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _apiService.deleteMessage(message['id'].toString());
    if (!mounted) return;
    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template removed'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${result['msg']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComposeSheet({Map<String, dynamic>? existingMessage}) {
    final isEditing = existingMessage != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: existingMessage?['title'] ?? '',
    );
    final contentController = TextEditingController(
      text: existingMessage?['content'] ?? '',
    );
    Uint8List? pickedImageBytes;
    String? pickedImageName;
    String? existingImageUrl = isEditing ? existingMessage['imgurl'] : null;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                final bytes = await image.readAsBytes();
                setSheetState(() {
                  pickedImageBytes = bytes;
                  pickedImageName = image.name;
                });
              }
            }

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;

              setSheetState(() => isSubmitting = true);

              Uint8List? imageBytesToSend = pickedImageBytes;
              String? imageNameToSend = pickedImageName;

              if (imageBytesToSend == null &&
                  isEditing &&
                  existingImageUrl != null) {
                try {
                  final imageBaseUrl = _webRoot ?? ApiService.baseUrl;
                  final imageUrl = imageBaseUrl + existingImageUrl;
                  final response = await http.get(Uri.parse(imageUrl));
                  if (response.statusCode == 200) {
                    imageBytesToSend = response.bodyBytes;
                    imageNameToSend = existingImageUrl.split('/').last;
                  }
                } catch (_) {}
              }

              if (imageBytesToSend == null) {
                setSheetState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an image (required)'),
                  ),
                );
                return;
              }

              Map<String, dynamic> result;
              if (isEditing) {
                result = await _apiService.modifyMessage(
                  messId: existingMessage['id'].toString(),
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  imageBytes: imageBytesToSend,
                  imageFileName: imageNameToSend!,
                );
              } else {
                result = await _apiService.createMessage(
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  imageBytes: imageBytesToSend,
                  imageFileName: imageNameToSend!,
                );
              }

              if (!sheetContext.mounted) return;
              if (result['code'] == 200) {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Message updated'
                          : 'Message created (ID: ${result['data']?['id']})',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadMessages();
              } else {
                setSheetState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed: ${result['msg']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Dispatch' : 'Compose Dispatch',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isDark
                                  ? Colors.white
                                  : const Color(0xFF0A1628),
                            ),
                          ),
                          Row(
                            children: [
                              if (isEditing)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    _confirmDelete(existingMessage);
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: _isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                onPressed: () => Navigator.pop(sheetContext),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        style: TextStyle(
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF0A1628),
                          fontSize: 13,
                        ),
                        decoration: _sheetFieldDecoration(
                          'Title',
                          required: true,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: contentController,
                        style: TextStyle(
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF0A1628),
                          fontSize: 13,
                        ),
                        decoration: _sheetFieldDecoration(
                          'Advisory Message Content',
                          required: true,
                        ),
                        maxLines: 4,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: _isDark
                                ? const Color(0xFF020617)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: pickedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    pickedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : (isEditing && existingImageUrl != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        (_webRoot ?? ApiService.baseUrl) +
                                            existingImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: _isDark
                                                        ? Colors.white24
                                                        : Colors.grey[400],
                                                    size: 36,
                                                  ),
                                                ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Tap to change',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 32,
                                        color: _isDark
                                            ? Colors.white24
                                            : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tap to select image *',
                                        style: TextStyle(
                                          color: _isDark
                                              ? Colors.white38
                                              : Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submit,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, size: 18),
                          label: Text(
                            isSubmitting
                                ? 'Submitting...'
                                : (isEditing
                                      ? 'UPDATE TEMPLATE'
                                      : 'CREATE TEMPLATE'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSendSheet(Map<String, dynamic> message) {
    List<Map<String, dynamic>> devices = [];
    final Set<String> selectedDeviceIds = {};
    bool isLoadingDevices = true;
    bool isSending = false;
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> loadDevices() async {
              final result = await _apiService.getOnlineDevices();
              if (result['code'] == 200) {
                final companies = List<Map<String, dynamic>>.from(
                  result['data']?['total'] ?? [],
                );
                List<Map<String, dynamic>> flatDevices = [];
                for (var company in companies) {
                  if (company['sub'] != null) {
                    flatDevices.addAll(
                      List<Map<String, dynamic>>.from(company['sub']),
                    );
                  }
                }
                setSheetState(() {
                  devices = flatDevices;
                  isLoadingDevices = false;
                });
              } else {
                setSheetState(() => isLoadingDevices = false);
              }
            }

            if (isLoadingDevices && devices.isEmpty) {
              loadDevices();
            }

            List<Map<String, dynamic>> filteredDevices() {
              final query = searchController.text.trim().toLowerCase();
              if (query.isEmpty) return devices;
              return devices.where((d) {
                final name = (d['hostname'] ?? '').toString().toLowerCase();
                final id = (d['did'] ?? '').toString().toLowerCase();
                return name.contains(query) || id.contains(query);
              }).toList();
            }

            final filtered = filteredDevices();
            final allSelected =
                filtered.isNotEmpty &&
                filtered.every((d) => selectedDeviceIds.contains(d['did']));

            void toggleSelectAll() {
              setSheetState(() {
                if (allSelected) {
                  for (var d in filtered) {
                    selectedDeviceIds.remove(d['did']);
                  }
                } else {
                  for (var d in filtered) {
                    selectedDeviceIds.add(d['did']);
                  }
                }
              });
            }

            Future<void> sendToSelected() async {
              if (selectedDeviceIds.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Select at least one device')),
                );
                return;
              }

              setSheetState(() => isSending = true);
              final result = await _apiService.sendMessage(
                messId: message['id'].toString(),
                deviceList: selectedDeviceIds.toList(),
              );
              if (!sheetContext.mounted) return;

              if (result['code'] == 200) {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sent to ${selectedDeviceIds.length} device(s)',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadMessages();
              } else {
                setSheetState(() => isSending = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed: ${result['msg']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Recipients',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isDark
                                      ? Colors.white
                                      : const Color(0xFF0A1628),
                                ),
                              ),
                              Text(
                                'Broadcast: ${message['title'] ?? ''}',
                                style: TextStyle(
                                  color: _isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: _isDark ? Colors.white70 : Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      style: TextStyle(
                        color: _isDark ? Colors.white : const Color(0xFF0A1628),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search officer name or device ID',
                        hintStyle: TextStyle(
                          color: _isDark ? Colors.white38 : Colors.grey[500],
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isDark ? Colors.white38 : Colors.grey[500],
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF9333EA),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: _isDark
                            ? const Color(0xFF020617)
                            : const Color(0xFFF8FAFC),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filtered.length} device(s)',
                          style: TextStyle(
                            color: _isDark ? Colors.white38 : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: filtered.isEmpty ? null : toggleSelectAll,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allSelected ? Icons.deselect : Icons.select_all,
                                size: 16,
                                color: const Color(0xFFC084FC),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                allSelected ? 'Deselect All' : 'Select All',
                                style: const TextStyle(
                                  color: Color(0xFFC084FC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: isLoadingDevices
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A9EFF),
                              ),
                            )
                          : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No devices available',
                                style: TextStyle(
                                  color: _isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final device = filtered[index];
                                final deviceId = device['did'] ?? '';
                                final isSelected = selectedDeviceIds.contains(
                                  deviceId,
                                );
                                final isOnline = device['lineon']?.toString() == '1';
                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selectedDeviceIds.remove(deviceId);
                                      } else {
                                        selectedDeviceIds.add(deviceId);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF9333EA,
                                            ).withOpacity(0.12)
                                          : (_isDark
                                                ? const Color(0xFF020617)
                                                : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(
                                                0xFF9333EA,
                                              ).withOpacity(0.5)
                                            : (_isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 20,
                                          color: isSelected
                                              ? const Color(0xFFC084FC)
                                              : (_isDark
                                                    ? Colors.white38
                                                    : Colors.grey[500]),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    device['hostname'] ??
                                                        'Unknown Officer',
                                                    style: TextStyle(
                                                      color: _isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF0A1628,
                                                            ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF2563EB,
                                                      ).withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '#$deviceId',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF60A5FA,
                                                        ),
                                                        fontSize: 9,
                                                        fontFamily: 'monospace',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: isOnline
                                                    ? Colors.greenAccent
                                                    : (_isDark
                                                          ? Colors.white24
                                                          : Colors.grey[400]),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOnline ? 'ONLINE' : 'OFFLINE',
                                              style: TextStyle(
                                                color: isOnline
                                                    ? Colors.greenAccent
                                                    : (_isDark
                                                          ? Colors.white38
                                                          : Colors.grey[500]),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSending ? null : sendToSelected,
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          isSending
                              ? 'TRANSMITTING...'
                              : 'DISPATCH TO ${selectedDeviceIds.length} UNITS',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _sheetFieldDecoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(
        color: _isDark ? Colors.white54 : Colors.black87,
        fontSize: 12,
      ),
      filled: true,
      fillColor: _isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
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
      backgroundColor: _isDark
          ? const Color(0xFF0A1628)
          : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: _isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _HoverIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                    isDark: _isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch Messages',
                          style: TextStyle(
                            color: _isDark
                                ? Colors.white
                                : const Color(0xFF0A1628),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Pre-defined Broadcast Advisories',
                          style: TextStyle(
                            color: _isDark ? Colors.white38 : Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _HoverIconButton(
                      icon: Icons.refresh,
                      onTap: _isLoading ? () {} : _loadMessages,
                      isLoading: _isLoading,
                      isDark: _isDark,
                    ),
                  ),
                  _HoverComposeButton(onTap: () => _showComposeSheet()),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: _isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: _isDark ? Colors.white : const Color(0xFF0A1628),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search dispatch templates & tactical codes...',
                  hintStyle: TextStyle(
                    color: _isDark ? Colors.white38 : Colors.grey[500],
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isDark ? Colors.white38 : Colors.grey[500],
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF9333EA),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: _isDark
                      ? const Color(0xFF020617)
                      : const Color(0xFFF8FAFC),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: _isDark ? Colors.white38 : Colors.grey[500],
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _loadMessages();
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _loadMessages(),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A9EFF),
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 40,
                            color: _isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No matching dispatch templates found.',
                            style: TextStyle(
                              color: _isDark
                                  ? Colors.white38
                                  : Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      color: const Color(0xFF4A9EFF),
                      backgroundColor: _isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      child: ResponsiveContent(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 10,
                                  left: 2,
                                  right: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'AVAILABLE ADVISORIES (${_messages.length})',
                                      style: TextStyle(
                                        color: _isDark
                                            ? Colors.white38
                                            : Colors.grey[500],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    Text(
                                      'TAP TO DISPATCH',
                                      style: TextStyle(
                                        color: _isDark
                                            ? Colors.white38
                                            : Colors.grey[500],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final message = _messages[index - 1];
                            final isSent = message['flag'] == '1';
                            final typeIndex = int.tryParse(
                              message['type']?.toString() ?? '',
                            );
                            final typeLabel =
                                (typeIndex != null &&
                                    typeIndex >= 0 &&
                                    typeIndex < _messTypes.length)
                                ? _messTypes[typeIndex]
                                : 'Notice';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HoverMessageCard(
                                onTap: () =>
                                    _showComposeSheet(existingMessage: message),
                                isDark: _isDark,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF9333EA,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF9333EA,
                                          ).withOpacity(0.4),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.podcasts,
                                        size: 18,
                                        color: Color(0xFFC084FC),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message['title'] ?? 'Untitled',
                                            style: TextStyle(
                                              color: _isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0A1628),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            message['content'] ?? '',
                                            style: TextStyle(
                                              color: _isDark
                                                  ? Colors.white54
                                                  : Colors.black87,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                typeLabel.toString(),
                                                style: TextStyle(
                                                  color: _isDark
                                                      ? Colors.white38
                                                      : Colors.grey[500],
                                                  fontSize: 10,
                                                ),
                                              ),
                                              if (isSent) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  '•',
                                                  style: TextStyle(
                                                    color: _isDark
                                                        ? Colors.white24
                                                        : Colors.grey[400],
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Sent',
                                                  style: TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    _HoverDeleteIcon(
                                      onTap: () => _confirmDelete(message),
                                      isDark: _isDark,
                                    ),
                                    const SizedBox(width: 12),
                                    _HoverSendButton(
                                      onTap: () => _showSendSheet(message),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
  final bool isLoading;
  final bool isDark;
  const _HoverIconButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
    this.isDark = true,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
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
            color: _isHovered
                ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                )
              : Icon(
                  widget.icon,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 18,
                ),
        ),
      ),
    );
  }
}

class _HoverComposeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverComposeButton({required this.onTap});

  @override
  State<_HoverComposeButton> createState() => _HoverComposeButtonState();
}

class _HoverComposeButtonState extends State<_HoverComposeButton> {
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
            color: _isHovered
                ? const Color(0xFFA855F7)
                : const Color(0xFF9333EA),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(_isHovered ? 0.5 : 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                'Compose',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverMessageCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;
  const _HoverMessageCard({
    required this.child,
    required this.onTap,
    this.isDark = true,
  });

  @override
  State<_HoverMessageCard> createState() => _HoverMessageCardState();
}

class _HoverMessageCardState extends State<_HoverMessageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF9333EA).withOpacity(0.5)
                  : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0)),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _HoverSendButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverSendButton({required this.onTap});

  @override
  State<_HoverSendButton> createState() => _HoverSendButtonState();
}

class _HoverSendButtonState extends State<_HoverSendButton> {
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF9333EA).withOpacity(0.3)
                : const Color(0xFF9333EA).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.send, size: 16, color: Color(0xFFC084FC)),
        ),
      ),
    );
  }
}

class _HoverDeleteIcon extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _HoverDeleteIcon({required this.onTap, this.isDark = true});

  @override
  State<_HoverDeleteIcon> createState() => _HoverDeleteIconState();
}

class _HoverDeleteIconState extends State<_HoverDeleteIcon> {
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
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFF43F5E).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.delete_outline,
            size: 19,
            color: _isHovered
                ? const Color(0xFFFB7185)
                : (widget.isDark ? Colors.white38 : Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
