//
//  ScannerViewController.swift
//  
//
//  Created by Diego Cid Merino on 8/1/24.
//

import AVFoundation
import UIKit

import AVFoundation
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var returnString: Bool = true

    public func inicializa(returnString: Bool) {
        self.returnString = returnString
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported",
                                   message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        guard let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }

        var parametros: [String: Any] = [:]

        if returnString {
            guard let stringValue = readableObject.stringValue else { return }
            captureSession.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            parametros["qrcode"] = stringValue
        } else {
            // Le pasamos el OBJETO completo, no el payload:
            // dentro decide entre stringValue (vía buena) y descriptor (fallback)
            guard let payload = extractPayload(from: readableObject) else {
                // Lectura inservible: no paramos la sesión, seguimos escaneando
                return
            }
            captureSession.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            parametros["qrcodeData"] = payload
        }

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "lecturaQR"),
                                        object: nil,
                                        userInfo: parametros)
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }

    func extractPayload(from object: AVMetadataMachineReadableCodeObject) -> Data? {
        guard let descriptor = object.descriptor as? CIQRCodeDescriptor else { return nil }

        let raw = descriptor.errorCorrectedPayload
        let version = descriptor.symbolVersion

        // 1. Reensamblado de segmentos a nivel de bits (la vía correcta)
        if let reassembled = QRSegmentDecoder.reassemble(payload: raw, version: version),
           reassembled.count > 2,
           reassembled[reassembled.startIndex] == 0xDC,
           reassembled[reassembled.startIndex + 1] == 0x03 {
            return reassembled
           }

        // 2. Fallback: payload crudo; alignToMagicByte del parser lo intentará
        return raw
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
