import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrdniflut/qrdniflut.dart'; // Asegúrate que el nombre coincida con tu pubspec.yaml

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Esperando...';
  final _plugin = Qrdniflut(); // Instancia de tu clase principal
  
  @override
  void initState() {
    _configurar();
    super.initState();
  }

  void _configurar() async {
    Map<String, String> misCertificados = {
        "PRODUCCION": "http://pki.policia.es/cnp/MiDNI/APPDNIMOVIL.cer",
        "PRUEBAS": "http://pki.policia.es/cnp/MiDNI/APPDNIMOVIL_pruebas.cer",
    };
    final res = await _plugin.configure("ENwxSJNttKp88QWpIKv7IrvwouTFcar8jvetYHIfTygZBj9zp5y52BvkjV7a6ohmBeCdRjxLWsm8NkVER7Mf9q5UowqDQnOfVZeGOY+ZmnVcwETbNhFsb2vAL2AoKZLJJ8G33tMo6uhflxmz18j/5Y2lwyv3bAYoIcfgDB5lpRRK0Zg+zFn14QTLoatdhesQD5y4toh7Abb59dtHkmw1gGdRqhnV9DM69vPMk2aDGUQ7Y5nnx15e1EO85ba6a38CERobw0F+i4XQsAHpkKt6CMqPv6dqiKngD9kFfpwLK5JIIjzJ4HWimzpLrm5vMVD+1wxtQbtEVe8aVxFgh+BIKQ==", certs: misCertificados);
    setState(() => _status = "Licencia: ${res?['descripcion']}");

  }

  void _escanear() async {

    var status = await Permission.camera.status;
      
      if (status.isDenied) {
        // Solicita el permiso al usuario
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        // Si el permiso es concedido, abre el escaer
        try {
          final res = await _plugin.abrirEscaner();
          setState(() => _status = "DNI: ${res?['dni']} - ${res?['name']}");
        } catch (e) {
          setState(() => _status = "Error: $e");
        }
      } else {
        setState(() => _status = "El usuario denegó el permiso de cámara");
      }
  }

  void _procesaQR() async{
    var qrB64 = "QEc9wDdYF1nqm1Jnw0EUv5G2YtXXhacflLtHLscflxwV4teV4teQgJYAhDLiBTT0wgMXIGTUFEUklEdAZNQURSSURiBk1BRFJJRHgGTUFEUklEZANFU1BmDEpPU0UgLyBNQVJJQWgJQ0FBMDAwNDgyQAkwMDAwMDQ0NVBCCjExLTAxLTE5ODBEBkNBUk1FTkYTRVNQQcORT0xBIEVTUEHDkU9MQUgBRkwKMTItMDktMjAyOFCCA2cAAAAMalAgIA0KhwoAAAAUZnR5cGpwMiAAAAAAanAyIAAAAC1qcDJoAAAAFmloZHIAAAHsAAABkAABBwcAAAAAAA9jb2xyAQAAAAAAEQAAAxpqcDJj/0//UQApAAAAAAGQAAAB7AAAAAAAAAAAAAABkAAAAewAAAAAAAAAAAABBwEB/1IADAAAAAEABQQEAAD/XAAjQncgdvB28HbAbwBvAG7gZ1BnUGdoUAVQBVBHV9NX01di/2QAJQABQ3JlYXRlZCBieSBPcGVuSlBFRyB2ZXJzaW9uIDIuNS4w/5AACgAAAAACiQAB/5PPp0cAFABF679O7a+9oMFkIShc8ti0CP9cyCa2UJMRfDVahWxs9YiL2SaBCjsj15hOWF6ivm4kP/LXaBD5lD6lhNF5v172zRUqD/QDSbThkID/HiyGK7+8DwodRyTUAKcNaJQV/gizZlwS9HhILS70hf7XFCG1I1u5eoSAPiWofbBKALyXvi8N4D2is7VvyWhypcPkokPjXw+RAFcaYBqxk7l5v5kpMuEeD5vj/yiLONwSONiS2vRDduBcIyyyJJI5PG3axcVMimPw9aA2LrJxqCwEk5oO8uv8/rp/CUrNN1axXeuklB1sL4+x8tyqvVmdXceT1SWLlft0+WroFVywie0LwbRNOHfYZ9ByKVU+iXCb+loo1zwni/dSTqSfVVdayJrCq8M4m/CRJd+sbcPh2+Hw3sHaEKQ87BrkFgSbPE1U/0a8Bi5s/MyHLUWTfWEpOI5bienxRq3aqOT8YA+u3YkCjXKWmDvMZ1WJMASyKyevEdIrDkUTw3HZxMeTbOgj+ORKNMW3mpuSAi/Ya5h8/aUvDItBCT457FgxrrNGb1GfeYwhaJR/nDIUIYUPoqrTsc9bONkESmp5ZSh6fsRi17qhju0JmJUq/tj41YQgPABkYvs95sSo4+5KzIGIqmQqpFqLeE4j9VgZ666pCYUL7GuMOtiuK0LBPNlTJQ9LsONnE17Duiw7SPIW2tignhVyWuVEg37Wg5ysSQ/A9YIYgfuWBH+5FbaZa3VuUtCJOXE3229/bvZ5oaxM2G16W5Gz0nCbhBzGuakvE20KvfCDJWo/CmDoXKgihZOQAhmkNUqCwATLC0Xij+xWtrlLHUotaLHFANuzcFXkgP/ZgBMxNy0wNi0yMDMwIDEwOjUzOjMw/0APh5Cm/rerg0PLxSwIIGxEghNlOUEJST6981cw8y0zN8rNlTIrgbuAIUacnN7lpTRvLIqX+51P27I8saYiBpSEDsEewR7BHsEewR7BHsEewR7BHsEewR7BHsEewR7BHsEQ==";    
    try {
          final res = await _plugin.validaMiDNIQR(qrB64);
          setState(() => _status = "DNI: ${res?['dni']} - ${res?['name']}");
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test QR DNI Flutter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status),
              ElevatedButton(onPressed: _configurar, child: const Text("Configurar")),
              ElevatedButton(onPressed: _escanear, child: const Text("Abrir Cámara")),
              ElevatedButton(onPressed: _procesaQR, child: const Text("Proces QR prueba")),
            ],
          ),
        ),
      ),
    );
  }
}