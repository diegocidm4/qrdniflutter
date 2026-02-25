package com.cqesolutions.qrdniflut;

import android.app.Activity;
import android.content.Intent;
import androidx.annotation.NonNull;

import com.cqesolutions.qrdnidroid_project.QRDNIdroid;
import com.cqesolutions.qrdnidroid_project.bean.MiDNIData;

import java.util.Map;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class QrdniflutPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private MethodChannel channel;
    private Activity activity;
    private Result pendingResult;
    private qrdni implementation = new qrdni();
    private static final int REQUEST_CODE_SCAN = 12345;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "qrdniflut");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "configure":
                String license = call.argument("license");
                Map<String, String> certs = call.argument("certs");
                // Adaptamos la respuesta de JSObject (Capacitor) a Map (Flutter)
                result.success(implementation.configure(activity, license, certs));
                break;

            case "validaMiDNIQR":
                String data = call.argument("data");
                implementation.validaMiDNIQR(activity, data, new QRDNIdroid.ResultCallback() {
                    @Override
                    public void onSuccess(MiDNIData dniData) {
                        result.success(implementation.mapMiDNIDataToMap(dniData));
                    }
                    @Override
                    public void onError(String errorMessage) {
                        result.error("VALIDATION_ERROR", errorMessage, null);
                    }
                });
                break;

            case "abrirEscaner":
                this.pendingResult = result;
                Intent intent = new Intent(activity, QrCodeScanner.class);
                intent.putExtra("returnString", false);
                activity.startActivityForResult(intent, REQUEST_CODE_SCAN);
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_CODE_SCAN) {
            if (pendingResult == null) {
                return false; // Evitamos el crash si ya se limpió el resultado
            }

            if (resultCode == Activity.RESULT_OK && data != null) {
                String base64QR = data.getStringExtra("qr_code");
                
                // Creamos una referencia local final para el callback
                final Result resultToUse = pendingResult;
                pendingResult = null; // Lo limpiamos inmediatamente para evitar llamadas duplicadas

                implementation.validaMiDNIQR(activity, base64QR, new QRDNIdroid.ResultCallback() {
                    @Override
                    public void onSuccess(MiDNIData dniData) {
                        // Usamos la referencia local segura
                        activity.runOnUiThread(() -> resultToUse.success(implementation.mapMiDNIDataToMap(dniData)));
                    }

                    @Override
                    public void onError(String errorMessage) {
                        activity.runOnUiThread(() -> resultToUse.error("SCAN_ERROR", errorMessage, null));
                    }
                });
            } else {
                pendingResult.error("CANCELLED", "Escaneo cancelado", null);
                pendingResult = null;
            }
            return true;
        }
        return false;
    }
    // --- Gestión del ciclo de vida de la Activity (Necesario en Flutter) ---
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override public void onDetachedFromActivityForConfigChanges() { this.activity = null; }
    @Override public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) { onAttachedToActivity(binding); }
    @Override public void onDetachedFromActivity() { this.activity = null; }
    @Override public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) { channel.setMethodCallHandler(null); }
}