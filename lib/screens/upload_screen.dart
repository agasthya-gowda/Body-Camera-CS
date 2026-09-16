import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/responsive_content.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<Map<String, dynamic>> _uploadQueue = [
    {
      'name': 'REC_20260810_143207',
      'size': '4.2 GB',
      'progress': 0.0,
      'status': 'pending',
      'speed': '0 MB/s',
    },
    {
      'name': 'REC_20260808_173401',
      'size': '1.8 GB',
      'progress': 0.0,
      'status': 'pending',
      'speed': '0 MB/s',
    },
  ];

  bool _isUploading = false;
  Timer? _timer;

  void _startUpload() {
    setState(() => _isUploading = true);
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        for (var item in _uploadQueue) {
          if (item['status'] == 'pending' || item['status'] == 'uploading') {
            item['status'] = 'uploading';
            item['progress'] = (item['progress'] + 0.02).clamp(0.0, 1.0);
            item['speed'] = '2.3 MB/s';
            if (item['progress'] >= 1.0) {
              item['status'] = 'done';
              item['speed'] = 'Done';
            }
          }
        }
        if (_uploadQueue.every((item) => item['status'] == 'done')) {
          _timer?.cancel();
          _isUploading = false;
        }
      });
    });
  }

  void _stopUpload() {
    _timer?.cancel();
    setState(() {
      _isUploading = false;
      for (var item in _uploadQueue) {
        if (item['status'] == 'uploading') {
          item['status'] = 'pending';
          item['speed'] = '0 MB/s';
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Upload to Server',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1628),
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  color: Colors.green[700],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '4G',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1A3A6B).withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Color(0xFF1A3A6B),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Auto-upload enabled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A6B),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Videos upload automatically via 4G/WiFi',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Queue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1628),
                    ),
                  ),
                  Text(
                    '${_uploadQueue.length} files',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _uploadQueue.length,
                  itemBuilder: (context, index) {
                    final item = _uploadQueue[index];
                    return _buildUploadItem(item);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? _stopUpload : _startUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUploading
                        ? Colors.red
                        : const Color(0xFF1A3A6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_isUploading ? Icons.stop : Icons.cloud_upload),
                  label: Text(
                    _isUploading ? 'Stop Upload' : 'Start Upload',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadItem(Map<String, dynamic> item) {
    final isDone = item['status'] == 'done';
    final isUploading = item['status'] == 'uploading';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF0A1628),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isDone)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                Text(
                  '${(item['progress'] * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF1A3A6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item['progress'],
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? Colors.green : const Color(0xFF1A3A6B),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['size'],
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                isDone
                    ? 'Upload complete'
                    : isUploading
                    ? item['speed']
                    : 'Waiting...',
                style: TextStyle(
                  color: isDone ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
