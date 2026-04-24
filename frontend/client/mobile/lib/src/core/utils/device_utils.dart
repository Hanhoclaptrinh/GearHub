import 'package:flutter/foundation.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';

class DeviceUtils {
  static Future<String> getDeviceId(SecureStorageService storage) async {
    final existing = await storage.deviceId;
    if (existing != null && existing.isNotEmpty) return existing;

    // tao device id
    final id =
        'mobile_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}';
    await storage.saveDeviceId(id);
    return id;
  }
}
