import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SendMessageScreen extends StatefulWidget {
  final Map<String, dynamic> message;

  const SendMessageScreen({super.key, required this.message});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _devices = [];
  final Set<String> _selectedDeviceIds = {};
  bool _isLoading = true;
  bool _isSending = false;

  List<Map<String, dynamic>> get _filteredDevices {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _devices;
    return _devices.where((d) {
      final name = (d['hostname'] ?? '').toString().toLowerCase();
      final id = (d['did'] ?? '').toString().toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  bool get _allSelected =>
      _filteredDevices.isNotEmpty &&
      _filteredDevices.every((d) => _selectedDeviceIds.contains(d['did']));

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getOnlineDevices();
    if (result['code'] == 200) {
      final companies = List<Map<String, dynamic>>.from(
        result['data']?['total'] ?? [],
      );
      List<Map<String, dynamic>> devices = [];
      for (var company in companies) {
        if (company['sub'] != null) {
          devices.addAll(List<Map<String, dynamic>>.from(company['sub']));
        }
      }
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        for (var d in _filteredDevices) {
          _selectedDeviceIds.remove(d['did']);
        }
      } else {
        for (var d in _filteredDevices) {
          _selectedDeviceIds.add(d['did']);
        }
      }
    });
  }

  Future<void> _sendToSelected() async {
    if (_selectedDeviceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one device')),
      );
      return;
    }

    setState(() => _isSending = true);
    final result = await _apiService.sendMessage(
      messId: widget.message['id'].toString(),
      deviceList: _selectedDeviceIds.toList(),
    );
    setState(() => _isSending = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent to ${_selectedDeviceIds.length} device(s)'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Send: ${widget.message['title'] ?? ''}',
            style: const TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? const Center(child: Text('No devices available'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search officer name or device ID',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_filteredDevices.length} device(s)', style: TextStyle(color: Colors.grey[600])),
                          TextButton.icon(
                            onPressed: _filteredDevices.isEmpty ? null : _toggleSelectAll,
                            icon: Icon(_allSelected ? Icons.deselect : Icons.select_all, size: 18),
                            label: Text(_allSelected ? 'Deselect All' : 'Select All'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredDevices.length,
                        itemBuilder: (context, index) {
                          final device = _filteredDevices[index];
                    final deviceId = device['did'] ?? '';
                    final isSelected = _selectedDeviceIds.contains(deviceId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedDeviceIds.add(deviceId);
                            } else {
                              _selectedDeviceIds.remove(deviceId);
                            }
                          });
                        },
                        title: Text(device['hostname'] ?? 'Unknown Officer'),
                        subtitle: Text('Device: $deviceId · ${device['lineon']?.toString() == '1' ? "Online" : "Offline"}'),
                        secondary: CircleAvatar(
                          backgroundColor: device['lineon']?.toString() == '1' ? Colors.green[50] : Colors.grey[200],
                          child: Icon(
                            Icons.videocam,
                            color: device['lineon']?.toString() == '1' ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendToSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSending
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Send to ${_selectedDeviceIds.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}