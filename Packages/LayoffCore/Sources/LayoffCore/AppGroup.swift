import Foundation

public enum AppGroup {
    /// Nil when the ID is empty, lacks a team prefix (starts with "."), or has an unexpanded build variable.
    public static func identifier(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty, !raw.hasPrefix("."), !raw.contains("$(") else { return nil }
        return raw
    }

    public static var current: String? {
        identifier(from: Bundle.main.object(forInfoDictionaryKey: "LCAppGroupID") as? String)
    }
}
