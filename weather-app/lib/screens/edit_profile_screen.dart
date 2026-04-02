import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/avatar_upload_service.dart';
import '../theme/neu_theme.dart';
import '../utils/i18n.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_container.dart';
import '../widgets/neu_input.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.userName);
    _emailController = TextEditingController(text: provider.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _requestPhotoPermission() async {
    final provider = context.read<AppProvider>();
    final lang = provider.language;

    PermissionStatus status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!mounted) {
        return false;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          final isDark = context.read<AppProvider>().isDarkMode;
          return AlertDialog(
            backgroundColor: NeuTheme.getBg(isDark),
            title: Text(
              I18n.get('avatar_permission_blocked', lang),
              style: TextStyle(color: NeuTheme.getPrimaryText(isDark)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: Text(I18n.get('open_settings', lang)),
              ),
            ],
          );
        },
      );
      return false;
    }

    _showMessage(I18n.get('avatar_permission_denied', lang));
    return false;
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar || _isSaving) {
      return;
    }

    final provider = context.read<AppProvider>();
    final lang = provider.language;
    final isDark = provider.isDarkMode;
    if (provider.userId.isEmpty) {
      _showMessage(I18n.get('avatar_upload_failed', lang));
      return;
    }

    final allowed = await _requestPhotoPermission();
    if (!allowed || !mounted) {
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1440,
      maxHeight: 1440,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: lang == 'zh' ? '裁剪头像' : 'Crop Avatar',
          toolbarColor: NeuTheme.getBg(isDark),
          toolbarWidgetColor: NeuTheme.getPrimaryText(isDark),
          backgroundColor: NeuTheme.getBg(isDark),
          activeControlsWidgetColor: NeuTheme.getPrimaryText(isDark),
          dimmedLayerColor: Colors.black54,
          lockAspectRatio: true,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: lang == 'zh' ? '裁剪头像' : 'Crop Avatar',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
        ),
      ],
    );

    if (croppedFile == null || !mounted) {
      return;
    }

    setState(() {
      _localAvatarPath = croppedFile.path;
      _isUploadingAvatar = true;
    });
    _showMessage(I18n.get('avatar_uploading', lang));

    try {
      final result = await AvatarUploadService.uploadAvatar(
        userId: provider.userId,
        file: XFile(croppedFile.path),
      );
      final error = await provider.updateProfileAvatar(result.avatarUrl);
      if (!mounted) {
        return;
      }
      setState(() => _isUploadingAvatar = false);
      if (error != null) {
        _showMessage(error);
        return;
      }
      _showMessage(I18n.get('avatar_updated', lang));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploadingAvatar = false;
        _localAvatarPath = null;
      });
      _showMessage(I18n.get('avatar_upload_failed', lang));
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) {
      return;
    }

    final provider = context.read<AppProvider>();
    final lang = provider.language;
    setState(() => _isSaving = true);
    final error = await provider.updateProfileName(_nameController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(I18n.get('profile_saved', lang));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;
    final avatarUrl = provider.userAvatar;
    final hasLocalAvatar =
        _localAvatarPath != null && _localAvatarPath!.isNotEmpty;
    final hasRemoteAvatar = avatarUrl.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              CommonHeader(title: lang == 'zh' ? "编辑资料" : "Edit Profile"),
              const SizedBox(height: 32),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NeuContainer(
                      width: 120,
                      height: 120,
                      shape: BoxShape.circle,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (hasLocalAvatar)
                            ClipOval(
                              child: Image.file(
                                File(_localAvatarPath!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (hasRemoteAvatar)
                            ClipOval(
                              child: Image.network(
                                avatarUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 64,
                                  color: NeuTheme.getPrimaryText(isDark),
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.person_rounded,
                              size: 64,
                              color: NeuTheme.getPrimaryText(isDark),
                            ),
                          if (_isUploadingAvatar)
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: NeuContainer(
                          width: 40,
                          height: 40,
                          shape: BoxShape.circle,
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                            color: NeuTheme.getPrimaryText(isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "   ${I18n.get('nickname', lang)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeuInput(
                    hint: I18n.get('enter_nickname', lang),
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "   ${lang == 'zh' ? '邮箱' : 'Email'}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeuInput(
                    icon: Icons.mail_rounded,
                    hint: "",
                    controller: _emailController,
                    readOnly: true,
                  ),
                ],
              ),
              const Spacer(),
              NeuButton(
                width: double.infinity,
                height: 64,
                radius: 32,
                onTap: _saveChanges,
                child: Center(
                  child: Text(
                    _isSaving
                        ? I18n.get('saving', lang)
                        : I18n.get('save_changes', lang),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
