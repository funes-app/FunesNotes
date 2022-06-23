import Foundation
import SwiftGraphStore
@testable import FunesNotes

class FakeNoteGraphCreator: NoteGraphCreating {
    var newPostAndChildren_calledCount = 0
    var newPostAndChildren_paramResource: Resource?
    var newPostAndChildren_paramContents: NoteContents?
    var newPostAndChildren_paramMetadata: NoteMeta?
    var newPostAndChildren_returnPost: Post?
    var newPostAndChildren_returnGraph: Graph?
    func newPostAndChildren(resource: Resource, contents: NoteContents, metadata: NoteMeta) -> (Post, Graph) {
        newPostAndChildren_calledCount += 1
        newPostAndChildren_paramResource = resource
        newPostAndChildren_paramContents = contents
        newPostAndChildren_paramMetadata = metadata
        
        return (newPostAndChildren_returnPost!,
                newPostAndChildren_returnGraph!)
    }
}
