package com.cqesolutions.qrdniflut;

import android.content.Context;
import android.graphics.Bitmap;
import android.util.Base64;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;      
import org.json.JSONObject;

import com.cqesolutions.qrdniflut.jj2000.J2kStreamDecoder;

import com.cqesolutions.qrdnidroid_project.QRDNIdroid;
import com.cqesolutions.qrdnidroid_project.bean.EstadoLicencia;
import com.cqesolutions.qrdnidroid_project.bean.MiDNIData;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

public class qrdni {

    public Map<String, Object> configure(Context context, String license, Map<String, String> certConfig) {
        // Convertimos el Map de certificados a un String JSON para tu librería
        String jsonConfig = null;
        if (certConfig != null && !certConfig.isEmpty()) {
            jsonConfig = new JSONObject(certConfig).toString();
        }

        EstadoLicencia estado = QRDNIdroid.getInstance(context).initialize(license, jsonConfig);

        Map<String, Object> ret = new HashMap<>();
        ret.put("descripcion", estado.descripcion);
        ret.put("APIKeyValida", estado.apiKeyValida);
        ret.put("lecturaQRHabilitada", estado.lecturaQRHabilitada);
        return ret;
    }

    public void validaMiDNIQR(Context context, String base64Data, QRDNIdroid.ResultCallback callback) {
        try {
            byte[] rawBytes = Base64.decode(base64Data, Base64.DEFAULT);
            QRDNIdroid.getInstance(context).processQR(rawBytes, callback);
        } catch (Exception e) {
            callback.onError("Error decodificando Base64: " + e.getMessage());
        }
    }

    // Mapeo manual similar al que hiciste en Swift
    public Map<String, Object> mapMiDNIDataToMap(MiDNIData data) {
        Map<String, Object> json = new HashMap<>();
        json.put("dni", data.dni);
        json.put("name", data.name);
        json.put("surnames", data.surnames);
        json.put("birthDate", data.birthDate);
        json.put("expiryDate", data.expiryDate);
        json.put("gender", data.gender);
        json.put("address", data.address);
        json.put("nationality", data.nationality);
        json.put("parents", data.parents);
        json.put("supportNumber", data.supportNumber);
        json.put("birthPlace1", data.birthPlace1);
        json.put("birthPlace2", data.birthPlace2);
        json.put("birthPlace3", data.birthPlace3);

        // Manejo de foto
        if (data.photoData != null) {
            try {
                // 1. Decodificar el J2K usando el .jar que acabas de añadir
                J2kStreamDecoder j2k = new J2kStreamDecoder();
                ByteArrayInputStream bis = new ByteArrayInputStream(data.photoData);
                Bitmap bitmap = j2k.decode(bis);

                if (bitmap != null) {
                    // 2. Convertir a JPEG estándar para que Ionic lo entienda
                    ByteArrayOutputStream out = new ByteArrayOutputStream();
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
                    byte[] jpegBytes = out.toByteArray();

                    // 3. Enviar a la parte web como Base64
                    json.put("photoData", Base64.encodeToString(jpegBytes, Base64.NO_WRAP));
                }
            } catch (Exception e) {
                e.printStackTrace();
                json.put("photoData", ""); // Evitamos enviar datos corruptos
            }
        } else {
            json.put("photoData", "");
        }

        json.put("isAdult", data.isAdult);
        
        // Criptografía y firmas
        json.put("rawSignature", data.rawSignature != null ? Base64.encodeToString(data.rawSignature, Base64.NO_WRAP) : "");
        json.put("signedData", data.signedData != null ? Base64.encodeToString(data.signedData, Base64.NO_WRAP) : "");
        json.put("certificateRef", data.certificateRef);
        json.put("type", data.type != null ? data.type.name() : "");

        // Verificación (Status Mapping)
        Map<String, Object> verificationJson = new HashMap<>();
        if (data.verificationResult != null) {
            String statusNative = data.verificationResult.status.name(); // .name() para obtener el String del Enum

            Log.d("QRDNI_DEBUG", "Estado nativo: " + statusNative);
            switch (statusNative) {
                case "VALID":
                    verificationJson.put("status", "VALID");
                    // Si tienes el certificado, añádelo aquí
                    // verificationJson.put("certificate", data.getCertificate());
                    break;
                case "INVALID":
                    verificationJson.put("status", "INVALID");
                    break;
                case "NO_CERTIFICATES":
                    verificationJson.put("status", "NO_CERTIFICATES");
                    break;
                case "INVALID_QR":
                    verificationJson.put("status", "INVALID_QR");
                    break;
                case "EXPIRATED_QR":
                    verificationJson.put("status", "EXPIRATED_QR");
                    break;
                default:
                    verificationJson.put("status", "INVALID");
                    break;
            }
        } else {
            verificationJson.put("status", "UNKNOWN");
        }
        json.put("verificationResult", verificationJson);

        json.put("qrDataExpiry", data.qrDataExpiry);
        json.put("fullBirthPlace", data.getFullBirthPlace());

        return json;
    }
}