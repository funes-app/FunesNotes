import Foundation

struct NoteMeta {
    let id: NoteId
    var title: String?
    var subtitle: String?
    
    var contentsLastModified: Date
    var metadataLastModified: Date
    var deleted: Bool
}

extension NoteMeta {
    init(_ contents: NoteContents,
         contentsLastModified: Date,
         metadataLastModified: Date,
         deleted: Bool = false) {
        let nonemptyLines = contents.text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let title = nonemptyLines.first
        let subtitle = nonemptyLines.dropFirst().first
        
        self.init(id: contents.id,
                  title: title,
                  subtitle: subtitle,
                  contentsLastModified: contentsLastModified,
                  metadataLastModified: metadataLastModified,
                  deleted: deleted)
    }
    
    func withDeleted(_ deleted: Bool) -> NoteMeta {
        NoteMeta(id: id,
                 title: title,
                 subtitle: subtitle,
                 contentsLastModified: contentsLastModified,
                 metadataLastModified: metadataLastModified,
                 deleted: deleted)
    }
    
    func withLastModified(_ lastModified: Date) -> NoteMeta {
        NoteMeta(id: id,
                 title: title,
                 subtitle: subtitle,
                 contentsLastModified: lastModified,
                 metadataLastModified: lastModified,
                 deleted: deleted)
    }
    
    func withMetadataLastModified(_ lastModified: Date) -> NoteMeta {
        NoteMeta(id: id,
                 title: title,
                 subtitle: subtitle,
                 contentsLastModified: contentsLastModified,
                 metadataLastModified: lastModified,
                 deleted: deleted)
    }
}

extension NoteMeta: Codable {
    private struct RawNoteMeta: Decodable {
        let id: NoteId
        let title: String?
        let subtitle: String?
        let deleted: Bool
        
        let lastModified: Date?
        let contentsLastModified: Date?
        let metadataLastModified: Date?
    }
    
    init(from decoder: Decoder) throws {
        let rawNoteMeta = try RawNoteMeta(from: decoder)
        
        self.id = rawNoteMeta.id
        self.title = rawNoteMeta.title
        self.subtitle = rawNoteMeta.subtitle
        self.deleted = rawNoteMeta.deleted
        
        if let contentsLastModified = rawNoteMeta.contentsLastModified {
            self.contentsLastModified = contentsLastModified
        } else if let contentsLastModified = rawNoteMeta.lastModified {
            self.contentsLastModified = contentsLastModified
        } else {
            self.contentsLastModified = Date.distantPast
        }
        
        self.metadataLastModified = rawNoteMeta.metadataLastModified ?? self.contentsLastModified
    }
}

extension NoteMeta: Equatable {}

extension NoteMeta: Identifiable {}

extension NoteMeta: Hashable {}

extension NoteMeta: FileURLNaming {
    static func idPathComponent(id: NoteId) -> String {
        "\(id)_meta"
    }
    
    static func isNoteMetaFile(_ fileURL: URL) -> Bool {
        fileURL.lastPathComponent.hasSuffix("_meta.json")
    }
}

extension NoteMeta: Comparable {
    static func < (lhs: NoteMeta, rhs: NoteMeta) -> Bool {
        lhs.contentsLastModified < rhs.contentsLastModified
    }
}
