import Flutter
import UIKit
import iQRDNI

public class QrdniflutPlugin: NSObject, FlutterPlugin {
    private let implementation = qrdni()
    private var pendingResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "qrdniflut", binaryMessenger: registrar.messenger())
        let instance = QrdniflutPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            guard let args = call.arguments as? [String: Any],
                  let license = args["license"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing license", details: nil))
                return
            }
            let certs = args["certs"] as? [String: String]
            let resultado = implementation.configure(license, certs)
            
            result([
                "descripcion": resultado.descripcion,
                "APIKeyValida": resultado.APIKeyValida,
                "lecturaQRHabilitada": resultado.lecturaQRHabilitada
            ])

        case "validaMiDNIQR":
            guard let args = call.arguments as? [String: Any],
                  let qrBase64 = args["data"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing data", details: nil))
                return
            }

            if let qrData = Data(base64Encoded: qrBase64) {
                if let resultadoJson = implementation.validaMiDNIQR(datosQR: qrData) {
                    result(resultadoJson)
                } else {
                    result(FlutterError(code: "VALIDATION_FAILED", message: "Validación fallida", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_BASE64", message: "Base64 corrupto", details: nil))
            }

        case "abrirEscaner":
            self.pendingResult = result
            DispatchQueue.main.async {
                let scannerVC = ScannerViewController()
                scannerVC.modalPresentationStyle = .fullScreen
                scannerVC.inicializa(returnString: false)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.handleScannerResult(_:)), name: NSNotification.Name("lecturaQR"), object: nil)
                
                if let rootVC = UIApplication.shared.delegate?.window??.rootViewController {
                    rootVC.present(scannerVC, animated: true)
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @objc func handleScannerResult(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("lecturaQR"), object: nil)
        
        guard let res = self.pendingResult else { return }
        self.pendingResult = nil

        guard let userInfo = notification.userInfo,
              let qrBase64 = userInfo["qrcode"] as? String else {
            res(FlutterError(code: "SCAN_ERROR", message: "Error al obtener datos", details: nil))
            return
        }

        if let qrData = Data(base64Encoded: qrBase64) {
            if let resultadoJson = self.implementation.validaMiDNIQR(datosQR: qrData) {
                res(resultadoJson)
            } else {
                res(FlutterError(code: "VALIDATION_FAILED", message: "Fallo en validación", details: nil))
            }
        } else {
            res(FlutterError(code: "INVALID_BASE64", message: "Base64 corrupto", details: nil))
        }
    }
}
