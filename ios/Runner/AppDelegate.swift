import Flutter
import UIKit
import GoogleMaps
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let deviceKeyTag = "com.hidden.gems.device.ecdsa.p256".data(using: .utf8)!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDN_4eZeJAeFTX-FBsuQLUvJ7l8qluPWiM")
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "hidden_gems/device_keys", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in self?.handleDeviceKey(call, result: result) }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleDeviceKey(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      let privateKey = try devicePrivateKey()
      switch call.method {
      case "getPublicKey":
        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let raw = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else { throw keyError(2) }
        let header = Data([0x30,0x59,0x30,0x13,0x06,0x07,0x2a,0x86,0x48,0xce,0x3d,0x02,0x01,0x06,0x08,0x2a,0x86,0x48,0xce,0x3d,0x03,0x01,0x07,0x03,0x42,0x00])
        result("-----BEGIN PUBLIC KEY-----\n\((header + raw).base64EncodedString())\n-----END PUBLIC KEY-----")
      case "sign":
        guard let args = call.arguments as? [String: Any], let payload = args["payload"] as? String else { throw keyError(3) }
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, .ecdsaSignatureMessageX962SHA256, Data(payload.utf8) as CFData, &error) as Data? else {
          throw error?.takeRetainedValue() ?? keyError(4)
        }
        result(signature.base64EncodedString())
      default: result(FlutterMethodNotImplemented)
      }
    } catch { result(FlutterError(code: "DEVICE_KEY_ERROR", message: error.localizedDescription, details: nil)) }
  }

  private func devicePrivateKey() throws -> SecKey {
    let query: [String: Any] = [kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: deviceKeyTag, kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecReturnRef as String: true]
    var item: CFTypeRef?
    if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let key = item as! SecKey? { return key }
    let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, .privateKeyUsage, nil)!
    var attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true, kSecAttrApplicationTag as String: deviceKeyTag, kSecAttrAccessControl as String: access]]
    attrs[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
    var error: Unmanaged<CFError>?
    if let key = SecKeyCreateRandomKey(attrs as CFDictionary, &error) { return key }
    attrs.removeValue(forKey: kSecAttrTokenID as String)
    guard let key = SecKeyCreateRandomKey(attrs as CFDictionary, &error) else { throw error?.takeRetainedValue() ?? keyError(5) }
    return key
  }

  private func keyError(_ code: Int) -> NSError { NSError(domain: "DeviceKey", code: code) }
}
