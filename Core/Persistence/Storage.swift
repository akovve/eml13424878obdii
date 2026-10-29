import Foundation

@MainActor
final class Storage {
    static let shared = Storage()
    private let fm = FileManager.default
    private var docs: URL { fm.urls(for: .documentDirectory, in: .userDomainMask).first! }

    func save<T: Encodable>(_ value: T, as filename: String) {
        let url = docs.appendingPathComponent(filename)
        if let data = try? JSONEncoder().encode(value) {
            try? data.write(to: url)
        }
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = docs.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}