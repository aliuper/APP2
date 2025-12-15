import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../models/playlist_model.dart';

class ChannelGroupSelector extends StatefulWidget {
  final PlaylistModel playlist;
  final List<String> selectedGroups;
  final Function(List<String>) onGroupsSelected;
  final VoidCallback onConfirm;

  const ChannelGroupSelector({
    super.key,
    required this.playlist,
    required this.selectedGroups,
    required this.onGroupsSelected,
    required this.onConfirm,
  });

  @override
  State<ChannelGroupSelector> createState() => _ChannelGroupSelectorState();
}

class _ChannelGroupSelectorState extends State<ChannelGroupSelector> {
  late List<String> _selectedGroups;
  late Map<String, int> _groupChannelCount;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _selectedGroups = List.from(widget.selectedGroups);
    _groupChannelCount = _calculateGroupChannelCount();
    _filteredGroups = _groupChannelCount.keys.toList();
    _searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterGroups);
    _searchController.dispose();
    super.dispose();
  }

  Map<String, int> _calculateGroupChannelCount() {
    final Map<String, int> count = {};
    for (final channel in widget.playlist.channels) {
      final group = channel.groupTitle;
      count[group] = (count[group] ?? 0) + 1;
    }
    return count;
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = _groupChannelCount.keys.toList();
      } else {
        _filteredGroups = _groupChannelCount.keys
            .where((group) => group.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleGroup(String group) {
    setState(() {
      if (_selectedGroups.contains(group)) {
        _selectedGroups.remove(group);
      } else {
        _selectedGroups.add(group);
      }
    });
    widget.onGroupsSelected(_selectedGroups);
  }

  void _toggleAll() {
    setState(() {
      if (_selectedGroups.length == _groupChannelCount.length) {
        _selectedGroups.clear();
      } else {
        _selectedGroups = List.from(_groupChannelCount.keys);
      }
    });
    widget.onGroupsSelected(_selectedGroups);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedGroups.length;
    final totalCount = _groupChannelCount.length;
    final allSelected = selectedCount == totalCount && totalCount > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kanal Grupları',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _toggleAll,
                      icon: Icon(
                        allSelected ? Icons.deselect : Icons.select_all,
                      ),
                      label: Text(allSelected ? 'Tümünü Kaldır' : 'Tümünü Seç'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Grup ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                // Selection summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_add_check,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$selectedCount / $totalCount grup seçildi',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Groups list
          Expanded(
            child: _filteredGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Grup bulunamadı',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = _filteredGroups[index];
                      final isSelected = _selectedGroups.contains(group);
                      final channelCount = _groupChannelCount[group] ?? 0;

                      return FadeIn(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggleGroup(group),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? const Color(0xFF6366F1).withOpacity(0.05)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Checkbox or icon
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFFCBD5E1),
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    // Group info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$channelCount kanal',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(0xFF64748B),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // TV icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                                .withOpacity(0.1)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.tv,
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom action button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedGroups.isEmpty ? null : widget.onConfirm,
                child: Text('Seçimi Onayla ($selectedCount)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}