package com.hidden.gems.hidden_gems_sl

import android.view.WindowManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugin.common.MethodChannel
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

class MainActivity : FlutterFragmentActivity() {
    private val deviceKeyAlias = "hidden_gems_device_ecdsa_p256"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val factory = NativeAdFactoryExample(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "adFactoryExample", factory)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hidden_gems/device_keys").setMethodCallHandler { call, result ->
            try {
                val entry = deviceKey()
                when (call.method) {
                    "getPublicKey" -> {
                        val value = Base64.encodeToString(entry.certificate.publicKey.encoded, Base64.NO_WRAP)
                        result.success("-----BEGIN PUBLIC KEY-----\n$value\n-----END PUBLIC KEY-----")
                    }
                    "sign" -> {
                        val payload = call.argument<String>("payload") ?: throw IllegalArgumentException("payload required")
                        val signer = Signature.getInstance("SHA256withECDSA")
                        signer.initSign(entry.privateKey)
                        signer.update(payload.toByteArray(Charsets.UTF_8))
                        result.success(Base64.encodeToString(signer.sign(), Base64.NO_WRAP))
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("DEVICE_KEY_ERROR", e.message, null)
            }
        }
    }

    private fun deviceKey(): KeyStore.PrivateKeyEntry {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!store.containsAlias(deviceKeyAlias)) {
            val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
            generator.initialize(KeyGenParameterSpec.Builder(deviceKeyAlias, KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY)
                .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .build())
            generator.generateKeyPair()
        }
        return store.getEntry(deviceKeyAlias, null) as KeyStore.PrivateKeyEntry
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "adFactoryExample")
    }
}
