
import 'qrdniflut_platform_interface.dart';

class Qrdniflut {

  /**
    * Método utilizado para configurar el plugin.
    * @param license (código de licencia generado que permite el uso del plugin)
    * @param certs (Map con las rutas de los certificados oficiales con los que pueden estar firmados los códigos QR generados)
    */
  Future<Map<String, dynamic>?> configure(String license, {Map<String, String>? certs}) async {
    return QrdniflutPlatform.instance.configure(license, certs: certs);

  }

  /**
    * Método utilizado para validar el código QR pasado como parámetro.
    * @param data (código QR leído de la app MiDNI)
    */
  Future<Map<String, dynamic>?> validaMiDNIQR(String data) async {
    return QrdniflutPlatform.instance.validaMiDNIQR(data);
  }

  /**
    * Método utilizado para abrir el escaner, leer el código QR y pasarlo a la validación del código QR.
    */
  Future<Map<String, dynamic>?> abrirEscaner() async {
    return QrdniflutPlatform.instance.abrirEscaner();
  }
}
