import Foundation
import Security

enum Credentials {
    static func query(_ account: String) -> [String: Any] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.sanztheo.MacWidgets",
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: false
        ]
        return query
    }

    static func read(_ account: String) throws -> Data? {
        var query = query(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw failure(status) }
        return result as? Data
    }

    static func save(_ data: Data, account: String) throws {
        let query = query(account)
        let values = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccess as String] = try accessControl()
            let added = SecItemAdd(item as CFDictionary, nil)
            guard added == errSecSuccess else { throw failure(added) }
        } else if status != errSecSuccess {
            throw failure(status)
        }
    }

    static func delete(_ account: String) throws {
        let status = SecItemDelete(query(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw failure(status) }
    }

    private static func failure(_ status: OSStatus) -> WidgetFailure {
        .message("Accès au Trousseau impossible (\(status)). Vérifiez la signature et les droits de partage.")
    }

    private static func accessControl() throws -> SecAccess {
        // macOS's file-based Keychain uses code-signature ACLs. This gives the two
        // signed executables access without claiming provisioned iOS entitlements.
        let bundle = Bundle.main.bundleURL
        let app = bundle.pathExtension == "appex"
            ? bundle.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            : bundle
        let widget = app.appendingPathComponent("Contents/PlugIns/MacWidgetsExtension.appex")
        var trustedApplications: [SecTrustedApplication] = []
        for url in [app, widget] {
            var trusted: SecTrustedApplication?
            let status = SecTrustedApplicationCreateFromPath(url.path, &trusted)
            guard status == errSecSuccess, let trusted else { throw failure(status) }
            trustedApplications.append(trusted)
        }
        var access: SecAccess?
        let status = SecAccessCreate("MacWidgets — comptes GitHub et Google" as CFString,
                                     trustedApplications as CFArray, &access)
        guard status == errSecSuccess, let access else { throw failure(status) }
        return access
    }
}
