import Foundation
import iQRDNI
import UIKit

@objc public class qrdni: NSObject {

    public func configure(_ license: String, _ certConfig: [String: String]? = nil)  -> EstadoLicencia {
        return iQRDNI.configure(apiKey: license, certConfig: certConfig)
    }

    public func validaMiDNIQR(datosQR: Data)  -> [String: Any]? {
        guard let miDNIData = iQRDNI.validaMiDNIQR(qrRawData: datosQR) else {
            return nil
        }

        var json: [String: Any] = [:]
        json["dni"] = miDNIData.dni ?? ""
        json["name"] = miDNIData.name ?? ""
        json["surnames"] = miDNIData.surnames ?? ""
        json["birthDate"] = miDNIData.birthDate ?? ""
        json["expiryDate"] = miDNIData.expiryDate ?? ""
        json["gender"] = miDNIData.gender ?? ""
        json["address"] = miDNIData.address ?? ""
        json["nationality"] = miDNIData.nationality ?? ""
        json["parents"] = miDNIData.parents ?? ""
        json["supportNumber"] = miDNIData.supportNumber ?? ""
        json["birthPlace1"] = miDNIData.birthPlace1 ?? ""
        json["birthPlace2"] = miDNIData.birthPlace2 ?? ""
        json["birthPlace3"] = miDNIData.birthPlace3 ?? ""

        

        if(miDNIData.photoData != nil)
        {
            if let photoImage = UIImage(data:miDNIData.photoData!)
            {
                let base64String = convertImageToBase64(image: photoImage)
                json["photoData"] = base64String
            }
            else
            {
                json["photoData"] = ""
            }
        }
        else
        {
            json["photoData"] = ""
        }

        if(miDNIData.isAdult != nil)
        {
            json["isAdult"] = miDNIData.isAdult
        }
        else
        {
            json["isAdult"] = false
        }
        
        json["rawSignature"] = miDNIData.rawSignature?.base64EncodedString() ?? ""
        json["signedData"] = miDNIData.signedData?.base64EncodedString() ?? ""
        json["certificateRef"] = miDNIData.certificateRef ?? ""
        
        if(miDNIData.type != nil)
        {           
            switch miDNIData.type!.rawValue as Int{
                case 0:
                    json["type"] = "EDAD"
                case 1:
                    json["type"] = "SIMPLE"
                case 2:
                    json["type"] = "COMPLETO"
                default:
                    json["type"] = ""
                }
        }
        
        if let result = miDNIData.verificationResult {
            var verificationJson: [String: Any] = [:]
            
            switch result {
            case .valid(let certificateName):
                verificationJson["status"] = "VALID"
                verificationJson["certificate"] = certificateName
            case .invalid:
                verificationJson["status"] = "INVALID"
            case .noCertificates:
                verificationJson["status"] = "NO_CERTIFICATES"
            case .invalidQR:
                verificationJson["status"] = "INVALID_QR"
            case .expiratedQR:
                verificationJson["status"] = "EXPIRED_QR"
            }
            
            json["verificationResult"] = verificationJson
        } else {
            json["verificationResult"] = ["status": "UNKNOWN"]
        }

        json["qrDataExpiry"] = miDNIData.qrDataExpiry ?? ""

        json["fullBirthPlace"] = miDNIData.fullBirthPlace ?? ""

        return json
    }

    public func convertImageToBase64(image: UIImage) -> String {
        let imageData = image.pngData()!
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
    }

}
