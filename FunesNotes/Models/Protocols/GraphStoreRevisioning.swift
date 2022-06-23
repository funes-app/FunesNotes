import Foundation
import UrsusHTTP
import SwiftGraphStore

protocol GraphStoreRevisioning: Codable {
    var id: NoteId { get }
    var contents: [Content] { get }    
    var contentsText: String { get }
    
    static func containerIndex(id: NoteId) -> Index
    static func revisionContainerIndex(id: NoteId, revision: Atom) -> Index
    static func revisionIndex(id: NoteId, revision: Atom) -> Index
        
    func makeRevisionGraph(ship: Ship, revision: Atom) -> Graph
}

extension GraphStoreRevisioning {
    var contents: [Content] {
        return [Content(text: contentsText)]
    }
    
    var contentsText: String {
        contentsTextForRevision(revision: self)
    }

    func contentsTextForRevision<T: GraphStoreRevisioning>(revision: T) -> String {
        guard let data = try? JSONEncoder().encode(revision),
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        return text
    }
    
    func makeRevisionGraph(ship: Ship,
                           revision: Atom) -> Graph {
        let index = Self.revisionIndex(id: id, revision: revision)
        
        let post = Post(ship: ship,
                        index: index,
                        contents: contents)
        return Graph(index: index, post: post, children: nil)!
    }
}
