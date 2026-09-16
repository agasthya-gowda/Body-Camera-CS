import 'package:flutter/material.dart';
import '../widgets/responsive_content.dart';

class VideosListScreen extends StatefulWidget {
  const VideosListScreen({super.key});

  @override
  State<VideosListScreen> createState() => _VideosListScreenState();
}

class _VideosListScreenState extends State<VideosListScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'All';

  final List<Map<String, dynamic>> _videos = [
    {
      'name': 'REC_20260810_143207',
      'date': 'Today',
      'quality': '1080p',
      'size': '4.2 GB',
      'duration': '12:34',
      'isEvidence': true,
      'isUploaded': false,
    },
    {
      'name': 'REC_20260809_091530',
      'date': 'Yesterday',
      'quality': '720p',
      'size': '2.1 GB',
      'duration': '08:17',
      'isEvidence': false,
      'isUploaded': true,
    },
    {
      'name': 'REC_20260808_173401',
      'date': '2 days ago',
      'quality': '1080p',
      'size': '1.8 GB',
      'duration': '05:02',
      'isEvidence': false,
      'isUploaded': false,
    },
    {
      'name': 'REC_20260807_120045',
      'date': '3 days ago',
      'quality': '1080p',
      'size': '3.5 GB',
      'duration': '10:21',
      'isEvidence': true,
      'isUploaded': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredVideos {
    return _videos.where((video) {
      final matchesSearch = video['name'].toString().toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final matchesFilter =
          _filterType == 'All' ||
          (_filterType == 'Evidence' && video['isEvidence']) ||
          (_filterType == 'Uploaded' && video['isUploaded']);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Videos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1628),
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search recordings...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['All', 'Evidence', 'Uploaded'].map((filter) {
                      final isSelected = _filterType == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _filterType = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1A3A6B)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredVideos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No videos found',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredVideos.length,
                      itemBuilder: (context, index) {
                        final video = _filteredVideos[index];
                        return _buildVideoItem(video);
                      },
                    ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            Container(
              width: 64,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: Color(0xFF4A9EFF),
                size: 28,
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video['duration'],
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                video['name'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A1628),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (video['isEvidence'])
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Evidence',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (video['isUploaded'])
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Uploaded',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${video['date']} · ${video['quality']} · ${video['size']}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 18),
                  SizedBox(width: 8),
                  Text('Play'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'upload',
              child: Row(
                children: [
                  Icon(Icons.upload, size: 18),
                  SizedBox(width: 8),
                  Text('Upload'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'evidence',
              child: Row(
                children: [
                  Icon(Icons.label, size: 18),
                  SizedBox(width: 8),
                  Text('Mark as Evidence'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog(video);
            } else if (value == 'evidence') {
              setState(() {
                video['isEvidence'] = !video['isEvidence'];
              });
            }
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text('Are you sure you want to delete ${video['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _videos.remove(video));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
