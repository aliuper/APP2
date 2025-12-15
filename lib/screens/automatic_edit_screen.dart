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
import '../services/link_tester_service.dart';
import '../services/m3u_parser_service.dart';
import '../services/country_detector_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_background.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AutomaticEditScreen extends ConsumerStatefulWidget {
  const AutomaticEditScreen({super.key});

  @override
  ConsumerState<AutomaticEditScreen> createState() => _AutomaticEditScreenState();
}

class _AutomaticEditScreenState extends ConsumerState<AutomaticEditScreen> {
  final _urlsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isTesting = false;
  List<String> _urls = [];
  List<LinkTestResult> _testResults = [];
  List<String> _selectedCountries = CountryDetectorService.getDefaultCountries();
  List<PlaylistModel> _workingPlaylists = [];

  @override
  void initState() {
    super.initState();
    _urlsController.addListener(_updateUrlsList);
  }

  @override
  void dispose() {
    _urlsController.removeListener(_updateUrlsList);
    _urlsController.dispose();
    super.dispose();
  }

  void _updateUrlsList() {
    final text = _urlsController.text;
    final urls = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line.startsWith('http'))
        .toList();
    setState(() {
      _urls = urls;
    });
  }

  Future<void> _loadFromTextFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final urls = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && line.startsWith('http'))
          .toList();

      setState(() {
        _urlsController.text = urls.join('\n');
        _urls = urls;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya okuma hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testLinks() async {
    if (_urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir URL girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isTesting = true;
      _testResults.clear();
      _workingPlaylists.clear();
    });

    try {
      // Test links with progress callback
      final results = await LinkTesterService.testPlaylistUrlsIsolate(
        _urls,
        onProgress: (result) {
          setState(() {
            _testResults.add(result);
          });
        },
      );

      // Get working playlists
      final workingUrls = results
          .where((r) => r.isWorking)
          .map((r) => r.url)
          .toList();

      for (final url in workingUrls) {
        try {
          final playlist = await M3UParserService.parseFromUrl(url);
          setState(() {
            _workingPlaylists.add(playlist);
          });
        } catch (e) {
          // Skip invalid playlists
        }
      }

      setState(() {
        _isLoading = false;
        _isTesting = false;
      });

      _showTestResults();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isTesting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTestResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Test Sonuçları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showProcessingOptions();
                    },
                    child: const Text('İlerle'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  final result = _testResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: result.isWorking ? Colors.green : Colors.red,
                        child: Icon(
                          result.isWorking ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        result.url,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.isWorking ? 'Çalışıyor' : 'Çalışmıyor',
                            style: TextStyle(
                              color: result.isWorking ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (result.isWorking) ...[
                            Text(
                              'Süre: ${result.responseTime}ms',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (result.testedChannels > 0)
                              Text(
                                'Kanal: ${result.workingChannels}/${result.testedChannels}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                          if (result.error != null)
                            Text(
                              result.error!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessingOptions() {
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
              'İşlem Seçimi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              icon: Icons.auto_fix_high_rounded,
              title: 'Otomatik Düzenle',
              subtitle: 'Akıllı ülke filtreleme ile',
              onPressed: () {
                Navigator.pop(context);
                _showCountrySelection();
              },
              isPrimary: true,
            ),
            const SizedBox(height: 12),
            AppButton(
              icon: Icons.edit_rounded,
              title: 'Manuel Düzenle',
              subtitle: 'Her playlist için ayrı ayrı',
              onPressed: () {
                Navigator.pop(context);
                _startManualEditing();
              },
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  void _showCountrySelection() {
    final countries = CountryDetectorService.getAllCountries();
    final availableCountries = _getAvailableCountries();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Öncelikli Ülkeleri Seçin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final isSelected = _selectedCountries.contains(country.code);
                  final isAvailable = availableCountries.contains(country.code);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: isAvailable ? (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCountries.add(country.code);
                        } else {
                          _selectedCountries.remove(country.code);
                        }
                      });
                    } : null,
                    title: Text(country.name),
                    subtitle: isAvailable
                        ? const Text('Bu ülkeden kanallar mevcut')
                        : Text('Bu ülkeden kanal bulunamadı',
                            style: TextStyle(color: Colors.grey[400])),
                    enabled: isAvailable,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedCountries.isNotEmpty
                      ? () {
                          Navigator.pop(context);
                          _processPlaylists();
                        }
                      : null,
                  child: const Text('Filtrele ve Kaydet'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAvailableCountries() {
    final availableCountries = <String>{};
    for (final playlist in _workingPlaylists) {
      for (final channel in playlist.channels) {
        final country = CountryDetectorService.getChannelCountry(channel);
        if (country != null) {
          availableCountries.add(country.code);
        }
      }
    }
    return availableCountries.toList();
  }

  Future<void> _processPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _requestStoragePermission();

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        if (await Permission.storage.isGranted ||
            await Permission.manageExternalStorage.isGranted) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            downloadsDir = Directory('${externalDir.path.split('Android')[0]}Download');
          }
        }
      }

      if (downloadsDir == null) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Create IPTV_Editor_Outputs folder
      final outputsDir = Directory('${downloadsDir.path}/IPTV_Editor_Outputs');
      if (!await outputsDir.exists()) {
        await outputsDir.create(recursive: true);
      }

      int savedCount = 0;
      for (final playlist in _workingPlaylists) {
        // Filter channels by selected countries
        final filteredChannels = CountryDetectorService.filterChannelsByCountries(
          playlist.channels,
          _selectedCountries,
        );

        if (filteredChannels.isNotEmpty) {
          // Create filtered playlist
          final filteredPlaylist = playlist.copyWith(
            channels: filteredChannels,
            totalChannels: filteredChannels.length,
          );

          // Generate filename
          final expiryDate = playlist.expiryDate ?? DateTime.now().add(const Duration(days: 365));
          final dateStr = '${expiryDate.day.toString().padLeft(2, '0')}.${expiryDate.month.toString().padLeft(2, '0')}.${expiryDate.year}';
          final cleanName = playlist.name.replaceAll(RegExp(r'[^\w\-_.]'), '_');
          final fileName = 'Bitis_${dateStr}_${cleanName}.m3u';
          final filePath = '${outputsDir.path}/$fileName';

          // Generate M3U content
          final content = M3UParserService.generateM3UContent(filteredPlaylist);

          // Save file
          final file = File(filePath);
          await file.writeAsString(content);
          savedCount++;
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount playlist kaydedildi'),
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
          content: Text('İşlem hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startManualEditing() {
    // Navigate to first working playlist for manual editing
    if (_workingPlaylists.isNotEmpty) {
      // This would navigate to a manual editing screen for each playlist
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manuel düzenleme özelliği yakında'),
          backgroundColor: Colors.blue,
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
    final workingCount = _testResults.where((r) => r.isWorking).length;
    final totalCount = _testResults.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Otomatik Düzenleme'),
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
                  'Toplu IPTV Linkleri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              FadeInLeft(
                duration: const Duration(milliseconds: 700),
                child: Text(
                  'Her satıra bir M3U URL\'i girin (maks. 10)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FadeInRight(
                duration: const Duration(milliseconds: 800),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _urlsController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'http://example.com/playlist1.m3u8\nhttp://example.com/playlist2.m3u8',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Lütfen en az bir URL girin';
                      }
                      final urls = value.split('\n').where((line) =>
                          line.trim().startsWith('http')).toList();
                      if (urls.isEmpty) {
                        return 'Geçerli bir URL girin';
                      }
                      if (urls.length > 10) {
                        return 'En fazla 10 URL girebilirsiniz';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FadeInUp(
                duration: const Duration(milliseconds: 900),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        icon: Icons.file_upload,
                        title: 'TXT Dosyadan Yükle',
                        onPressed: _loadFromTextFile,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        icon: Icons.speed_rounded,
                        title: 'Linkleri Test Et',
                        onPressed: _isTesting ? null : _testLinks,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_isTesting) ...[
                Center(
                  child: Column(
                    children: [
                      LoadingAnimationWidget.staggeredDotsWave(
                        color: const Color(0xFF6366F1),
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Linkler test ediliyor...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (totalCount > 0)
                        Text(
                          'İşlenen: $totalCount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              if (_testResults.isNotEmpty && !_isTesting) ...[
                FadeIn(
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
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Toplam Test',
                            '$totalCount',
                            Icons.playlist_add_check,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Çalışan',
                            '$workingCount',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Başarısız',
                            '${totalCount - workingCount}',
                            Icons.error,
                            Colors.red,
                          ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}