import 'dart:async';

import 'package:crypto/crypto.dart' as crypto;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_credentials.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

import 'api_service.dart';

class AvatarUploadResult {
  const AvatarUploadResult({required this.avatarUrl, required this.objectKey});

  final String avatarUrl;
  final String objectKey;
}

class AvatarUploadService {
  static const String bucket = 'static-1257938258';
  static const String region = 'ap-chongqing';
  static const String _basePrefix = 'flwoerweather/avatar';

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await Cos().initWithSessionCredential(_AvatarCredentialFetcher());
    final config = CosXmlServiceConfig(region: region, isHttps: true);
    await Cos().registerDefaultService(config);
    await Cos().registerDefaultTransferManger(
      config,
      TransferConfig(forceSimpleUpload: true, enableVerification: false),
    );
    _initialized = true;
  }

  static Future<AvatarUploadResult> uploadAvatar({
    required String userId,
    required XFile file,
  }) async {
    await _ensureInitialized();
    await Cos().forceInvalidationCredential();

    final bytes = await file.readAsBytes();
    final fileContentMd5 = crypto.md5.convert(bytes).toString();
    final extension = path.extension(file.path).replaceFirst('.', '').trim();
    final sanitizedName = _sanitizeFileName(
      path.basenameWithoutExtension(file.name),
    );
    final fileName = sanitizedName.isEmpty
        ? 'avatar_${DateTime.now().millisecondsSinceEpoch}'
        : sanitizedName;
    final objectKey = extension.isEmpty
        ? '$_basePrefix/$userId/$fileContentMd5/$fileName'
        : '$_basePrefix/$userId/$fileContentMd5/$fileName.$extension';

    final completer = Completer<void>();
    await Cos().getDefaultTransferManger().upload(
      bucket,
      objectKey,
      region: region,
      filePath: file.path,
      resultListener: ResultListener(
        (_, __) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        (clientException, serviceException) {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception(
                serviceException?.errorMessage ??
                    serviceException?.httpMsg ??
                    clientException?.message ??
                    'Failed to upload avatar',
              ),
            );
          }
        },
      ),
    );

    await completer.future;
    return AvatarUploadResult(
      avatarUrl: 'https://$bucket.cos.$region.myqcloud.com/$objectKey',
      objectKey: objectKey,
    );
  }

  static String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }
}

class _AvatarCredentialFetcher implements IFetchCredentials {
  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() async {
    final data = await ApiService.getAvatarUploadCredentials();
    final credentials = Map<String, dynamic>.from(
      data['credentials'] as Map? ?? const {},
    );

    return SessionQCloudCredentials(
      secretId: credentials['tmpSecretId']?.toString() ?? '',
      secretKey: credentials['tmpSecretKey']?.toString() ?? '',
      token: credentials['sessionToken']?.toString() ?? '',
      startTime: (data['startTime'] as num?)?.toInt(),
      expiredTime: (data['expiredTime'] as num?)?.toInt() ?? 0,
    );
  }
}
