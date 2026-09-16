import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme_controller.dart';
import '../widgets/responsive_content.dart';
import 'add_officer_screen.dart';
import 'modify_officer_screen.dart';

class OfficerListScreen extends StatefulWidget {
  const OfficerListScreen({super.key});

  @override
  State<OfficerListScreen> createState() => _OfficerListScreenState();
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  const _HoverIconButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
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
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
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

class _HoverAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverAddButton({required this.onTap});

  @override
  State<_HoverAddButton> createState() => _HoverAddButtonState();
}

class _HoverAddButtonState extends State<_HoverAddButton> {
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
                ? const Color(0xFF10B981)
                : const Color(0xFF059669),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(_isHovered ? 0.5 : 0.3),
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
                'Add',
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

class _HoverOfficerCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverOfficerCard({required this.child, required this.onTap});

  @override
  State<_HoverOfficerCard> createState() => _HoverOfficerCardState();
}

class _HoverOfficerCardState extends State<_HoverOfficerCard> {
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF059669).withOpacity(0.4)
                  : Colors.transparent,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _OfficerListScreenState extends State<OfficerListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _officers = [];
  Map<String, dynamic> _userTypes = {};
  bool _isLoading = true;

  String? _filterBh;
  String? _filterType;
  String? _filterBind;
  Timer? _debounceTimer;

  bool get _hasActiveFilters =>
      _filterBh != null || _filterType != null || _filterBind != null;

  bool get _isDark => AppTheme.isDark(context);

  @override
  void initState() {
    super.initState();
    _loadOfficers();
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
      _loadOfficers();
    });
  }

  Future<void> _loadOfficers() async {
    setState(() => _isLoading = true);
    final searchText = _searchController.text.trim();
    final result = await _apiService.searchUsers(
      hostkey: searchText.isEmpty ? null : searchText,
      bh: _filterBh,
      type: _filterType,
      bind: _filterBind,
    );
    if (result['code'] == 200) {
      final data = result['data'];
      setState(() {
        _officers = List<Map<String, dynamic>>.from(data['policelist'] ?? []);
        _userTypes = Map<String, dynamic>.from(data['user_type'] ?? {});
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load officers: ${result['msg']}')),
        );
      }
    }
  }

  void _showFilterSheet() {
    String? tempBh = _filterBh;
    String? tempType = _filterType;
    String? tempBind = _filterBind;
    final isDark = _isDark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Officers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0A1628),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'UNIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.grey[700],
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: tempBh,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0A1628),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter unit name',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF020617)
                            : const Color(0xFFF8FAFC),
                      ),
                      onChanged: (v) =>
                          tempBh = v.trim().isEmpty ? null : v.trim(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OFFICER TYPE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.grey[700],
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._userTypes.entries.map(
                          (e) => _darkChip(
                            label: e.value.toString(),
                            selected: tempType == e.key,
                            isDark: isDark,
                            onTap: () => setSheetState(
                              () => tempType = tempType == e.key ? null : e.key,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DEVICE BINDING',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.grey[700],
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _darkChip(
                          label: 'All',
                          selected: tempBind == null,
                          isDark: isDark,
                          onTap: () => setSheetState(() => tempBind = null),
                        ),
                        _darkChip(
                          label: 'Bound',
                          selected: tempBind == '1',
                          isDark: isDark,
                          onTap: () => setSheetState(() => tempBind = '1'),
                        ),
                        _darkChip(
                          label: 'Not Bound',
                          selected: tempBind == '2',
                          isDark: isDark,
                          onTap: () => setSheetState(() => tempBind = '2'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempBh = null;
                                tempType = null;
                                tempBind = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterBh = tempBh;
                                _filterType = tempType;
                                _filterBind = tempBind;
                              });
                              Navigator.pop(context);
                              _loadOfficers();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
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

  Widget _darkChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB).withOpacity(0.2)
              : (isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF60A5FA)
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _typeLabel(String? typeCode) {
    return _userTypes[typeCode]?.toString() ?? typeCode ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A1628)
          : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Officers',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0A1628),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Personnel & Badge Registry',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[500],
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
                      onTap: _isLoading ? () {} : _loadOfficers,
                      isLoading: _isLoading,
                    ),
                  ),
                  _HoverAddButton(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddOfficerScreen(userTypes: _userTypes),
                        ),
                      );
                      _loadOfficers();
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0A1628),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name, badge # or unit...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF020617)
                            : const Color(0xFFF8FAFC),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadOfficers();
                                },
                              )
                            : null,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _loadOfficers(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HoverIconButton(
                        icon: Icons.tune,
                        onTap: _showFilterSheet,
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A9EFF),
                      ),
                    )
                  : _officers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 40,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No officers match your search criteria.',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOfficers,
                      color: const Color(0xFF4A9EFF),
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      child: ResponsiveContent(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _officers.length,
                          itemBuilder: (context, index) {
                            final officer = _officers[index];
                            return _HoverOfficerCard(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ModifyOfficerScreen(
                                      officer: officer,
                                      userTypes: _userTypes,
                                    ),
                                  ),
                                );
                                _loadOfficers();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF059669,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF059669,
                                          ).withOpacity(0.4),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (officer['realname'] ?? '?')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  officer['realname'] ??
                                                      'Unknown',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0A1628,
                                                          ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2563EB,
                                                    ).withOpacity(0.4),
                                                  ),
                                                ),
                                                child: Text(
                                                  '#${officer['hostcode']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF60A5FA),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                _typeLabel(officer['type']),
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white24
                                                      : Colors.grey[400],
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.apartment,
                                                size: 11,
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.grey[500],
                                              ),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  officer['bh'] ?? '',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.grey[500],
                                                    fontSize: 10,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((officer['mobile'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  size: 10,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.grey[500],
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  officer['mobile'].toString(),
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.grey[500],
                                                    fontSize: 10,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey[500],
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
