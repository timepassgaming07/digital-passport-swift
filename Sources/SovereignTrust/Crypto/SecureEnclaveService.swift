import Foundation
import CryptoKit
import Security
import LocalAuthentication

enum SecureEnclaveError: LocalizedError {
    case notAvailable, keyCreationFailed, keyNotFound, signFailed, exportFailed
    var errorDescription: String? {
        switch self {
        case .notAvailable:    return "Secure Enclave not available on this device"
        case .keyCreationFailed: return "Failed to create Secure Enclave key"
        case .keyNotFound:     return "Key not found in Secure Enclave"
        case .signFailed:      return "Signing operation failed"
        case .exportFailed:    return "Public key export failed"
        }
    }
}

actor SecureEnclaveService {
    static let shared = SecureEnclaveService()
    private init() {}
    private let tag = AppConstants.seKeyTag.data(using:.utf8)!

    // Query or create a P-256 key in the Secure Enclave
    func getOrCreateKey() throws -> SecKey {
        // 1. Try to find existing
        let query: CFDictionary = [
            kSecClass:           kSecClassKey,
            kSecAttrKeyType:     kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrTokenID:     kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationTag: tag,
            kSecReturnRef:       true,
        ] as CFDictionary
        var item: CFTypeRef?
        if SecItemCopyMatching(query, &item) == errSecSuccess, let key = item {
            return (key as! SecKey)
        }
        // 2. Create new
        var cfErr: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryAny], &cfErr) else {
            throw SecureEnclaveError.keyCreationFailed
        }
        let attrs: CFDictionary = [
            kSecAttrKeyType:     kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrTokenID:     kSecAttrTokenIDSecureEnclave,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent:    true,
                kSecAttrApplicationTag: tag,
                kSecAttrAccessControl:  access,
            ] as CFDictionary,
        ] as CFDictionary
        guard let key = SecKeyCreateRandomKey(attrs, &cfErr) else {
            throw SecureEnclaveError.keyCreationFailed
        }
        return key
    }

    func publicKeyData() throws -> Data {
        let priv = try getOrCreateKey()
        guard let pub = SecKeyCopyPublicKey(priv),
              let data = SecKeyCopyExternalRepresentation(pub, nil) else {
            throw SecureEnclaveError.exportFailed
        }
        return data as Data
    }

    func fingerprint() throws -> String {
        let data = try publicKeyData()
        let b64 = data.base64EncodedString()
        return "SE-\(String(b64.prefix(16)))"
    }

    func sign(payload: Data) throws -> Data {
        let key = try getOrCreateKey()
        var err: Unmanaged<CFError>?
        guard let sig = SecKeyCreateSignature(key,
            .ecdsaSignatureMessageX962SHA256, payload as CFData, &err) else {
            throw err?.takeRetainedValue() ?? SecureEnclaveError.signFailed
        }
        return sig as Data
    }

    func generateDID() throws -> String {
        let pubData = try publicKeyData()
        let hash = SHA256.hash(data: pubData)
        let hex = hash.map { String(format:"%02x",$0) }.joined()
        return "did:sov:\(String(hex.prefix(22)))"
    }
}
