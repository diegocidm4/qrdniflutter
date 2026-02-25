package com.cqesolutions.qrdniflut;

import android.content.Intent;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;

import com.google.zxing.Result;

import me.dm7.barcodescanner.zxing.ZXingScannerView;

public class QrCodeScanner extends AppCompatActivity implements ZXingScannerView.ResultHandler {
    public static final String KEY_QR_CODE = "qr_code";
    private ZXingScannerView mScannerView;
    private Boolean returnString = true;
    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        // Programmatically initialize the scanner view
        mScannerView = new ZXingScannerView(this);
        // Set the scanner view as the content view
        if(getIntent().hasExtra("returnString")) {
            returnString = (Boolean) getIntent().getExtras().get("returnString");
        }

        setContentView(mScannerView);
    }

    @Override
    public void onResume() {
        super.onResume();
        // Register ourselves as a handler for scan results.
        mScannerView.setResultHandler(this);
        // Start camera on resume
        mScannerView.startCamera();
    }

    @Override
    public void onPause() {
        super.onPause();
        // Stop camera on pause
        mScannerView.stopCamera();
    }

    @Override
    public void handleResult(Result rawResult) {
        if(returnString)
        {
            Intent intent = new Intent();
            intent.putExtra(KEY_QR_CODE, rawResult.getText());
            setResult(RESULT_OK, intent);
            finish();
        }
        else {
            Log.i("QrCodeScanner", "QR detectado");
            // 1. OBTENER BYTES CRUDOS (CRÍTICO PARA DNI 4.0)
            // No uses getText() para datos binarios
            byte[] rawBytes = rawResult.getRawBytes();

            if (rawBytes != null && rawBytes.length > 0) {

                // 2. CONVERTIR A BASE64
                // Como tu fragmento 'DatosMiDnie' espera un String y hace un Base64.decode,
                // aquí debemos hacer el Base64.encode.
                String base64Result = Base64.encodeToString(rawBytes, Base64.NO_WRAP);

                // Debug: Ver longitud
                Log.d("QrCodeScanner", "Bytes leídos: " + rawBytes.length);

                // 3. RETORNAR EL RESULTADO
                Intent intent = new Intent();
                intent.putExtra(KEY_QR_CODE, base64Result);
                setResult(RESULT_OK, intent);
                finish();
            } else {
                // Si falla la lectura de bytes, reanudamos la cámara
                mScannerView.resumeCameraPreview(this);
            }
        }
    }

}