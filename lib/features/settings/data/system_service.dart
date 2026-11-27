import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/presentation/library_controller.dart';

class SystemService {
  static const MethodChannel _channel = MethodChannel('soundwave/library');

  Future<bool> notificationsEnabled() async =>
      (await _channel.invokeMethod<bool>('notificationsEnabled')) ?? true;

  Future<void> openNotificationSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');

  Future<void> openAppSettings() => _channel.invokeMethod<void>('openSettings');
}

final systemServiceProvider = Provider<SystemService>((ref) => SystemService());

class PermissionInfo {
  final bool media;
  final bool notifications;
  const PermissionInfo({required this.media, required this.notifications});
}

final permissionInfoProvider = FutureProvider.autoDispose<PermissionInfo>((
  ref,
) async {
  final media = await ref.read(scannerServiceProvider).hasPermission();
  final notifications = await ref
      .read(systemServiceProvider)
      .notificationsEnabled();
  return PermissionInfo(media: media, notifications: notifications);
});
