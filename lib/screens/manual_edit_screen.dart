import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../models/playlist_model.dart';
import '../models/channel_model.dart';
import '../services/m3u_parser_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_background.dart';
import '../widgets/channel_group_selector.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ManualEditScreen extends ConsumerStatefulWidget {
  const ManualEditScreen({super.key});

  @override
  ConsumerState<ManualEditScreen> createState() => _ManualEditScreenState();
}

class _ManualEditScreenState extends ConsumerState<ManualEditScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isParsing = false;
  PlaylistModel? _playlist;
  List<String> _selectedGroups = [];
  String _outputFormat = 'm3u8';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isParsing = true;
    });

    try {
      final url = _urlController.text.trim();
      final playlist = await M3UParserService.parseFromUrl(url);

      setState(() {
        _playlist = playlist;
        _selectedGroups = [];
        _isLoading = false;
        _isParsing = false;
      });

      _showGroupsSelection();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isParsing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final fileName = result.files.first.name;

      setState(() {
        _isLoading = true;
        _isParsing = true;
      });

      final playlist = await M3UParserService.parseFromContent(
        content,
        playlistName: fileName,
      );

      setState(() {
        _playlist = playlist;
        _selectedGroups = [];
        _urlController.text = fileName;
        _isLoading = false;
        _isParsing = false;
      });

      _showGroupsSelection();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isParsing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGroupsSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChannelGroupSelector(
        playlist: _playlist!,
        selectedGroups: _selectedGroups,
        onGroupsSelected: (groups) {
          setState(() {
            _selectedGroups = groups;
          });
        },
        onConfirm: () {
          Navigator.pop(context);
          _showFormatSelection();
        },
      ),
    );
  }

  void _showFormatSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Çıktı Formatını Seçin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildFormatOption('m3u8', 'M3U8', 'En Yaygın Format', true),
            _buildFormatOption('m3u', 'M3U', 'Standart Format', false),
            _buildFormatOption('plus', 'M3U Plus', 'Gelişmiş Özellikler', false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _savePlaylist();
                },
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String value, String title, String subtitle, bool isRecommended) {
    return InkWell(
      onTap: () {
        setState(() {
          _outputFormat = value;
        });
        Navigator.pop(context);
        _savePlaylist();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _outputFormat == value
                ? const Color(0xFF6366F1)
                : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(12),
          color: _outputFormat == value
              ? const Color(0xFF6366F1).withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Önerilen',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _outputFormat,
              onChanged: (value) {
                setState(() {
                  _outputFormat = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePlaylist() async {
    if (_playlist == null || _selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir grup seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check permissions
      await _requestStoragePermission();

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // For Android 10+, use Downloads directory
        if (await Permission.storage.isGranted ||
            await Permission.manageExternalStorage.isGranted) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to Downloads directory
            downloadsDir = Directory('${externalDir.path.split('Android')[0]}Download');
          }
        }
      }

      if (downloadsDir == null) {
        // Fallback to app documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Create IPTV_Editor_Outputs folder
      final outputsDir = Directory('${downloadsDir.path}/IPTV_Editor_Outputs');
      if (!await outputsDir.exists()) {
        await outputsDir.create(recursive: true);
      }

      // Generate filename
      final fileName = '${_playlist!.name}_filtered.${_outputFormat}';
      final filePath = '${outputsDir.path}/$fileName';

      // Generate M3U content
      final content = M3UParserService.generateM3UContent(
        _playlist!,
        selectedGroups: _selectedGroups,
      );

      // Save file
      final file = File(filePath);
      await file.writeAsString(content);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist kaydedildi: $fileName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      // Go back to home
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Düzenleme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'M3U Playlist URL\'i Girin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FadeInLeft(
                duration: const Duration(milliseconds: 700),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'http://example.com/playlist.m3u8',
                      labelText: 'Playlist URL',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Lütfen bir URL girin';
                      }
                      if (!value.startsWith('http')) {
                        return 'Geçerli bir URL girin';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FadeInRight(
                duration: const Duration(milliseconds: 800),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        icon: Icons.cloud_download,
                        title: 'Playlist\'i İndir',
                        onPressed: _isParsing ? null : _loadPlaylist,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        icon: Icons.file_upload,
                        title: 'Dosya Seç',
                        onPressed: _isParsing ? null : _loadFromFile,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_isLoading && _isParsing)
                Center(
                  child: Column(
                    children: [
                      LoadingAnimationWidget.staggeredDotsWave(
                        color: const Color(0xFF6366IF1),
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Playlist işleniyor...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_playlist != null && !_isLoading) ...[
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Playlist Bilgileri',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('İsim', _playlist!.name),
                        _buildInfoRow('Toplam Kanal', '${_playlist!.totalChannels}'),
                        _buildInfoRow('Seçili Grup', '${_selectedGroups.length}'),
                        if (_playlist!.expiryDate != null)
                          _buildInfoRow(
                            'Bitiş Tarihi',
                            '${_playlist!.expiryDate!.day}.${_playlist!.expiryDate!.month}.${_playlist!.expiryDate!.year}',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}