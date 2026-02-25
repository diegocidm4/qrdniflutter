import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qrdniflut_method_channel.dart';

abstract class QrdniflutPlatform extends PlatformInterface {
  /// Constructs a QrdniflutPlatform.
  QrdniflutPlatform() : super(token: _token);

  static final Object _token = Object();

  static QrdniflutPlatform _instance = MethodChannelQrdniflut();

  /// The default instance of [QrdniflutPlatform] to use.
  ///
  /// Defaults to [MethodChannelQrdniflut].
  static QrdniflutPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QrdniflutPlatform] when
  /// they register themselves.
  static set instance(QrdniflutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<String, dynamic>?> configure(String license, {Map<String, String>? certs}) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  Future<Map<String, dynamic>?> validaMiDNIQR(String data) {
    throw UnimplementedError('validaMiDNIQR() has not been implemented.');
  }

  Future<Map<String, dynamic>?> abrirEscaner() {
    throw UnimplementedError('abrirEscaner() has not been implemented.');
  }
}
