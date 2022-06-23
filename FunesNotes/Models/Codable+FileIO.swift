import Foundation

extension Encodable {
    func writeToFile(_ fileURL: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        try data.write(to: fileURL, options: .atomic)
    }
}

extension Decodable {
    init(_ fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}
