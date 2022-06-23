import Foundation
import SwiftGraphStore

protocol NoteGraphCreating {
    func newPostAndChildren(resource: Resource, contents: NoteContents, metadata: NoteMeta) -> (Post, Graph)
}
