import Foundation
import UrsusHTTP
import SwiftGraphStore
import SwiftUI

extension NoteContents: GraphStoreRevisioning {
    static func containerIndex(id: NoteId) -> Index {
        GraphStoreIndex
            .noteContentsContainer(id: id)
            .index
    }
    
    static func revisionContainerIndex(id: NoteId, revision: Atom) -> Index {
        GraphStoreIndex
            .noteContentsRevisionContainer(id: id, revision: revision)
            .index
    }
    
    static func revisionIndex(id: NoteId, revision: Atom) -> Index {
        GraphStoreIndex
            .noteContentsRevision(id: id, revision: revision)
            .index
    }
}
