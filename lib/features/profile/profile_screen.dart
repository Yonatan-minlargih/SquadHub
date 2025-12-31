import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/theme/bloc/theme_bloc.dart';
import '../../core/theme/bloc/theme_event.dart';
import '../../core/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = auth.FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(
      text: '',
    ); // Phone usually needs custom storage

    // Fetch detailed user data from Firestore
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _phoneController.text = data?['phone'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      await storageRef.putData(await image.readAsBytes());
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'avatarUrl': downloadUrl},
      );

      // Update Firebase Auth display name/photo
      await user.updatePhotoURL(downloadUrl);

      if (mounted) {
        NotificationService().showTopNotification(
          context,
          title: 'Photo Updated',
          body: 'Profile photo updated successfully!',
          icon: Iconsax.image,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showTopNotification(
          context,
          title: 'Upload Failed',
          body: 'Failed to upload image: $e',
          icon: Iconsax.danger,
          backgroundColor: Colors.red.shade400,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isEditing = false);

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text,
              'phone': _phoneController.text,
            });
        await user.updateDisplayName(_nameController.text);
      }

      if (mounted) {
        NotificationService().showTopNotification(
          context,
          title: 'Profile Saved',
          body: 'Profile updated successfully!',
          icon: Iconsax.user_tick,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showTopNotification(
          context,
          title: 'Save Failed',
          body: 'Failed to save profile: $e',
          icon: Iconsax.danger,
          backgroundColor: Colors.red.shade400,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.watch<ThemeBloc>().state.themeMode;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Iconsax.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: auth.FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(auth.FirebaseAuth.instance.currentUser!.uid)
                  .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final avatarUrl = userData?['avatarUrl'] as String?;
          final name = userData?['name'] as String? ?? 'User';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                          image:
                              avatarUrl != null && avatarUrl.startsWith('http')
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            avatarUrl == null || !avatarUrl.startsWith('http')
                            ? Center(
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.surface,
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Iconsax.camera, size: 18),
                              onPressed: _isUploading
                                  ? null
                                  : _pickAndUploadImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  enabled: _isEditing,
                  icon: Iconsax.user,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  enabled: _isEditing,
                  icon: Iconsax.message,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  enabled: _isEditing,
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Settings Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Settings', style: AppTextStyles.h3),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: Icon(isDark ? Iconsax.moon : Iconsax.sun),
                  value: isDark,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(ThemeToggled());
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text(
                    'Receive alerts for safe walks & expenses',
                  ),
                  secondary: const Icon(Iconsax.notification),
                  value: userData?['notificationsEnabled'] ?? true,
                  onChanged: (value) {
                    NotificationService().updateNotificationPreference(value);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !enabled,
        fillColor: enabled
            ? null
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
    );
  }
}
