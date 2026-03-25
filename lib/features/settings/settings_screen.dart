import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/session_providers.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('ja'));
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _displayNameController = TextEditingController();
  String? _loadedName;
  String? _loadedImageSource;
  Future<String?>? _imageDisplayUrlFuture;
  bool _savingProfile = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.displayNameRequired)));
      return;
    }

    setState(() => _savingProfile = true);
    try {
      await ref.read(routeDataRepositoryProvider).saveUserSettings(name: name);
      _loadedName = name;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.apiError}: $err')));
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<String?> _resolveDisplayImageUrl(String source) async {
    if (source.isEmpty) return null;
    if (source.startsWith('https://') || source.startsWith('http://')) {
      return source;
    }

    final supabase = ref.read(supabaseClientProvider);
    try {
      final signedUrl = await supabase.storage
          .from('profiles')
          .createSignedUrl(source, 60 * 60 * 24 * 7);
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  String _sanitizeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.isEmpty) return 'profile.webp';
    return sanitized;
  }

  String _guessImageContentType(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    if (extension == 'png') return 'image/png';
    if (extension == 'jpg' || extension == 'jpeg') return 'image/jpeg';
    if (extension == 'webp') return 'image/webp';
    return '';
  }

  Future<void> _pickAndUploadProfileImage() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _uploadingImage = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return;

      final contentType = _guessImageContentType(file);
      if (contentType.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileImageTypeError)));
        return;
      }

      if (bytes.length > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileImageSizeError)));
        return;
      }

      final objectPath =
          'users/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(file.name)}';
      final supabase = ref.read(supabaseClientProvider);
      await supabase.storage
          .from('profiles')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      await ref
          .read(routeDataRepositoryProvider)
          .saveUserSettings(imageUrl: objectPath);
      ref.invalidate(userSettingsProvider);
      _loadedImageSource = objectPath;
      _imageDisplayUrlFuture = _resolveDisplayImageUrl(objectPath);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileImageUpdated)));
      setState(() {});
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.apiError}: $err')));
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).valueOrNull ?? const {};
    final role = settings['role']?.toString() ?? 'guest';
    final email = settings['email']?.toString() ?? '';
    final displayName = settings['name']?.toString() ?? '';
    final imageSource = settings['imageUrl']?.toString() ?? '';
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (_loadedName != displayName) {
      _loadedName = displayName;
      _displayNameController.text = displayName;
    }
    if (_loadedImageSource != imageSource) {
      _loadedImageSource = imageSource;
      _imageDisplayUrlFuture = _resolveDisplayImageUrl(imageSource);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profile,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: _imageDisplayUrlFuture,
                  builder: (context, snapshot) {
                    final imageUrl = snapshot.data;
                    final imageProvider =
                        (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null;
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _uploadingImage
                              ? null
                              : _pickAndUploadProfileImage,
                          icon: _uploadingImage
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.image_outlined),
                          label: Text(l10n.updateProfileImage),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: l10n.displayName,
                    hintText: l10n.displayNameHint,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.email}: $email',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.saveProfile),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(title: Text(l10n.role), subtitle: Text(role)),
        ),
        Card(
          child: ListTile(
            title: Text(l10n.language),
            subtitle: Text(locale.languageCode),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'ja', child: Text('日本語')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                ref.read(localeProvider.notifier).state = Locale(value);
                final prefs = await ref.read(sharedPreferencesProvider.future);
                await prefs.setString('app_locale', value);
                await ref
                    .read(routeDataRepositoryProvider)
                    .saveUserSettings(language: value);
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(l10n.theme),
            subtitle: Text(themeMode.name),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                ref.read(themeModeProvider.notifier).state = value;
                final prefs = await ref.read(sharedPreferencesProvider.future);
                await prefs.setString('theme_mode', value.name);
                await ref
                    .read(routeDataRepositoryProvider)
                    .saveUserSettings(theme: value.name);
              },
            ),
          ),
        ),
      ],
    );
  }
}
