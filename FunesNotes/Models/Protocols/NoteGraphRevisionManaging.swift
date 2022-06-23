import Foundation
import SwiftGraphStore

protocol NoteGraphRevisionManaging {
    func getResourceState() async throws -> GraphConfigurationState

    func getLastRevisionNumber<T: GraphStoreRevisioning>(type: T.Type, id: NoteId) async throws -> Atom
    
    func getRevision<T: GraphStoreRevisioning>(id: NoteId, revision: Atom) async throws -> T
    
    func saveRevision<T: GraphStoreRevisioning>(revision: T, revisionNumber: Atom) async throws
}
