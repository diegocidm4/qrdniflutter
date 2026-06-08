package com.cqesolutions.qrdniflut;

import android.content.Intent;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.DecodeHintType;
import com.google.zxing.Result;
import com.google.zxing.ResultMetadataType;
import com.google.zxing.ResultPoint;
import com.journeyapps.barcodescanner.BarcodeCallback;
import com.journeyapps.barcodescanner.BarcodeResult;
import com.journeyapps.barcodescanner.BarcodeView;
import com.journeyapps.barcodescanner.DefaultDecoderFactory;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;



public class QrCodeScanner extends AppCompatActivity {
    public static final String KEY_QR_CODE = "qr_code";
    private BarcodeView mBarcodeView;
    private Boolean returnString = true;
    private boolean handled = false; // evita procesar el mismo QR dos veces

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);

        if (getIntent().hasExtra("returnString")) {
            returnString = (Boolean) getIntent().getExtras().get("returnString");
        }

        mBarcodeView = new BarcodeView(this);

        // CONFIGURACIÓN CLAVE: forzar ISO-8859-1 para que los segmentos byte
        // se decodifiquen 1:1 y getText() reconstruya el payload sin pérdida
        Map<DecodeHintType, Object> hints = new HashMap<>();
        hints.put(DecodeHintType.CHARACTER_SET, "ISO-8859-1");
        hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);

        mBarcodeView.setDecoderFactory(new DefaultDecoderFactory(
                Collections.singletonList(BarcodeFormat.QR_CODE), // solo QR
                hints,
                "ISO-8859-1",
                0)); // 0 = scan normal

        mBarcodeView.setFramingRectSize(new com.journeyapps.barcodescanner.Size(1200, 1200));

        setContentView(mBarcodeView);
        mBarcodeView.decodeContinuous(callback);
    }

    @Override
    public void onResume() {
        super.onResume();
        mBarcodeView.resume();
    }

    @Override
    public void onPause() {
        super.onPause();
        mBarcodeView.pause();
    }
    private final BarcodeCallback callback = new BarcodeCallback() {
        @Override
        public void barcodeResult(BarcodeResult barcodeResult) {
            handleResult(barcodeResult.getResult()); // Result original de ZXing
        }

        @Override
        public void possibleResultPoints(List<ResultPoint> resultPoints) {
            // No necesario
        }
    };

    private void handleResult(Result rawResult) {
        if (handled) return;

        if (returnString) {
            handled = true;
            Intent intent = new Intent();
            intent.putExtra(KEY_QR_CODE, normalizeText(rawResult.getText()));
            setResult(RESULT_OK, intent);
            finish();
        } else {
            Log.i("QrCodeScanner", "QR detectado");

            byte[] rawBytes = extractPayload(rawResult);

            if (rawBytes != null && rawBytes.length > 0) {
                handled = true;
                String base64Result = Base64.encodeToString(rawBytes, Base64.NO_WRAP);
                Log.d("QrCodeScanner", "Bytes leídos: " + rawBytes.length);

                Intent intent = new Intent();
                intent.putExtra(KEY_QR_CODE, base64Result);
                setResult(RESULT_OK, intent);
                finish();
            } else {
                // En modo continuo no hace falta reanudar nada:
                // el escáner sigue intentándolo solo
                Log.w("QrCodeScanner", "Payload vacío, reintentando...");
            }
        }
    }

    private byte[] extractPayload(Result result) {
        // 1. Reconstrucción vía texto (con ISO-8859-1 forzado es determinista)
        String text = result.getText();
        if (text != null && !text.isEmpty()) {
            byte[] full = text.getBytes(StandardCharsets.ISO_8859_1);
            if (full.length > 2 && (full[0] & 0xFF) == 0xDC && (full[1] & 0xFF) == 0x03) {
                Log.d("QrCodeScanner", "Payload vía getText (completo)");
                return full;
            }
        }

        // 2. Fallback: byte segments
        Map<ResultMetadataType, Object> meta = result.getResultMetadata();
        if (meta != null && meta.containsKey(ResultMetadataType.BYTE_SEGMENTS)) {
            List<byte[]> segments = (List<byte[]>) meta.get(ResultMetadataType.BYTE_SEGMENTS);
            if (segments != null && !segments.isEmpty()) {
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                for (byte[] seg : segments) {
                    bos.write(seg, 0, seg.length);
                }
                byte[] payload = bos.toByteArray();
                if (payload.length > 0) {
                    Log.d("QrCodeScanner", "Payload vía BYTE_SEGMENTS (fallback)");
                    return payload;
                }
            }
        }
        return result.getRawBytes(); // último recurso
    }

    /**
     * El decoder está forzado a ISO-8859-1 (necesario para QRs binarios del DNI).
     * Para QRs de texto, eso convierte el UTF-8 real en mojibake (Ã±, Ã¡...).
     * Como ISO-8859-1 es 1:1 con los bytes, podemos recuperar los bytes originales
     * y re-decodificarlos como UTF-8 si son UTF-8 válido.
     */
    private String normalizeText(String text) {
        if (text == null || text.isEmpty()) return text;
        byte[] raw = text.getBytes(StandardCharsets.ISO_8859_1);
        if (isValidUtf8(raw)) {
            return new String(raw, StandardCharsets.UTF_8);
        }
        return text; // ASCII puro o Latin-1 real: se queda como está
    }

    private boolean isValidUtf8(byte[] bytes) {
        java.nio.charset.CharsetDecoder decoder = StandardCharsets.UTF_8.newDecoder();
        try {
            decoder.decode(java.nio.ByteBuffer.wrap(bytes));
            return true;
        } catch (java.nio.charset.CharacterCodingException e) {
            return false;
        }
    }
}