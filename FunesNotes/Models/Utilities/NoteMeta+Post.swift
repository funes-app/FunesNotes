import Foundation
import UrsusHTTP
import SwiftGraphStore

extension NoteMeta: GraphStoreRevisioning {
    var withoutText: NoteMeta {
        NoteMeta(id: id,
                 title: nil,
                 subtitle: nil,
                 contentsLastModified: contentsLastModified,
                 metadataLastModified: metadataLastModified,
                 deleted: deleted)
    }
    
    var contentsText: String {
        contentsTextForRevision(revision: withoutText)
    }
    
    static func containerIndex(id: NoteId) -> Index {
        GraphStoreIndex
            .noteMetadataContainer(id: id)
            .index
    }
    
    static func revisionContainerIndex(id: NoteId, revision: Atom) -> Index {
        GraphStoreIndex
            .noteMetadataRevisionContainer(id: id, revision: revision)
            .index
    }
    
    static func revisionIndex(id: NoteId, revision: Atom) -> Index {
        GraphStoreIndex
            .noteMetadataRevision(id: id, revision: revision)
            .index
    }
    
    init(contents: NoteContents, metadata: NoteMeta) {
        self.init(contents,
                  contentsLastModified: metadata.contentsLastModified,
                  metadataLastModified: metadata.metadataLastModified,
                  deleted: metadata.deleted)
    }
}
