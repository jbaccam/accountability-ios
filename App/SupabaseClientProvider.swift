import Foundation
import Supabase

/// Configured Supabase client singleton. Reads URL/anon key from Info.plist
/// (injected from Secrets.xcconfig). Decoders convert snake_case columns to the
/// camelCase model properties and parse Postgres timestamps flexibly.
enum Supa {
    static let client: SupabaseClient = {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !anonKey.isEmpty
        else {
            fatalError("Missing SupabaseURL / SupabaseAnonKey in Info.plist (set Secrets.xcconfig).")
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: makeEncoder(),
                    decoder: makeDecoder()
                ),
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainSessionStorage(),
                    redirectToURL: URL(string: "accountability://auth-callback"),
                    autoRefreshToken: true
                )
            )
        )
    }()

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = PostgresDate.parse(raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unparseable date: \(raw)"
            )
        }
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

/// Parses the several timestamp shapes Postgres/PostgREST emit.
enum PostgresDate {
    private static let formatters: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [withFraction, plain]
    }()

    private static let spaceFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func parse(_ raw: String) -> Date? {
        for f in formatters {
            if let date = f.date(from: raw) { return date }
        }
        // PostgREST sometimes returns "yyyy-MM-dd HH:mm:ss(+00)".
        let trimmed = String(raw.prefix(19))
        return spaceFormatter.date(from: trimmed)
    }
}
