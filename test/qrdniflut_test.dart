import 'package:flutter_test/flutter_test.dart';
import 'package:qrdniflut/qrdniflut.dart';
import 'package:qrdniflut/qrdniflut_platform_interface.dart';
import 'package:qrdniflut/qrdniflut_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockQrdniflutPlatform
    with MockPlatformInterfaceMixin
    implements QrdniflutPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  
  @override
  Future<Map<String, dynamic>?> abrirEscaner() {
    // TODO: implement abrirEscaner
    throw UnimplementedError();
  }
  
  @override
  Future<Map<String, dynamic>?> configure(String license, {Map<String, String>? certs}) {
    // TODO: implement configure
    throw UnimplementedError();
  }
  
  @override
  Future<Map<String, dynamic>?> validaMiDNIQR(String data) {
    // TODO: implement validaMiDNIQR
    throw UnimplementedError();
  }
}

void main() {
  final QrdniflutPlatform initialPlatform = QrdniflutPlatform.instance;

  test('$MethodChannelQrdniflut is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQrdniflut>());
  });

  test('getPlatformVersion', () async {
    Qrdniflut qrdniflutPlugin = Qrdniflut();
    MockQrdniflutPlatform fakePlatform = MockQrdniflutPlatform();
    QrdniflutPlatform.instance = fakePlatform;

    //expect(await qrdniflutPlugin.getPlatformVersion(), '42');
  });
}
