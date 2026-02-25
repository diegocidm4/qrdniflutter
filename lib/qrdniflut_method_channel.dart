import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qrdniflut_platform_interface.dart';

/// An implementation of [QrdniflutPlatform] that uses method channels.
class MethodChannelQrdniflut extends QrdniflutPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qrdniflut');

  @override
  Future<Map<String, dynamic>?> configure(String license, {Map<String, String>? certs}) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('configure', {
      'license': license,
      'certs': certs,
    });
    return result;
  }

  @override
  Future<Map<String, dynamic>?> validaMiDNIQR(String data) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('validaMiDNIQR', {
      'data': data,
    });
    return result;
  }

  @override
  Future<Map<String, dynamic>?> abrirEscaner() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('abrirEscaner');
    return result;
  }
}
