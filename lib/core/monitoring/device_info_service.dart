import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;

  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();

    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';
    String platform = 'unknown';

    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      deviceModel = '${android.manufacturer} ${android.model}';
      osVersion = 'Android ${android.version.release}';
      platform = 'android';
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      deviceModel = ios.utsname.machine ?? 'iPhone';
      osVersion = 'iOS ${ios.systemVersion}';
      platform = 'ios';
    }

    return {
      'device_model': deviceModel,
      'os_version': osVersion,
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'platform': platform,
    };
  }
}
