import Foundation

struct JSONLoader {
    static func load<T: Decodable>(_ filename: String) throws -> T {
        let data: Data

        let sourceFile = URL(fileURLWithPath: #file)
        let sourceDir = sourceFile.deletingLastPathComponent().appendingPathComponent("../Resources")
        let file = sourceDir.appendingPathComponent(filename)

        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Couldn't parse \(filename) as \(T.self):\n\(error)")
            throw error
        }
    }
}
