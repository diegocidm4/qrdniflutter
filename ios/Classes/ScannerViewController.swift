//
//  ScannerViewController.swift
//  ValidAge
//
//  Created by Diego Cid Merino on 8/1/24.
//

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
        view.backgroundColor = .black

        // Creamos la sesión
        captureSession = AVCaptureSession()

        // Ejecutamos la configuración pesada en segundo plano
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if (self.captureSession.canAddInput(videoInput)) {
                self.captureSession.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if (self.captureSession.canAddOutput(metadataOutput)) {
                self.captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            // La UI sí se actualiza en el Main Thread
            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.frame = self.view.layer.bounds
                self.previewLayer.videoGravity = .resizeAspectFill
                self.view.layer.addSublayer(self.previewLayer)
                
                // Iniciamos la sesión fuera del hilo principal de nuevo
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
/*
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        var parametros: [String: Any] = [String: Any] ()
        if(self.returnString)
        {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                parametros["qrcode"] = stringValue
            }
        }
        else {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                    
                    // IMPORTANTE: Accedemos al descriptor, no al stringValue.
                    // El descriptor contiene los bytes crudos (RAW) del QR.
                    if let descriptor = metadataObject.descriptor as? CIQRCodeDescriptor {
                        
                        let rawPayload = descriptor.errorCorrectedPayload
                        //print("Datos brutos: \(rawPayload.toPrettyHexString())")
                        parametros["qrcodeData"] = rawPayload
                    }
                }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "lecturaQR"), object: nil, userInfo: parametros)
    }
*/
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // 1. Detenemos la sesión inmediatamente para evitar múltiples lecturas
        // startRunning/stopRunning siempre fuera del hilo principal si es posible
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }

        // 2. Procesamos los datos
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let descriptor = metadataObject.descriptor as? CIQRCodeDescriptor else {
            // Si falla, reiniciamos sesión
            DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
            return
        }

        let rawPayload = descriptor.errorCorrectedPayload
        let base64String = rawPayload.base64EncodedString()
        
        // Feedback táctico
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // 3. TODO el proceso pesado de validación y cierre debe ir fuera del hilo UI
        // pero el 'dismiss' debe volver al Main para no congelar la pantalla
        DispatchQueue.main.async {
            let parametros: [String: Any] = ["qrcode": base64String]
            
            // Notificamos al Plugin
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: "lecturaQR"),
                object: nil,
                userInfo: parametros
            )
            
            // Cerramos la cámara
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
