import Foundation
import SwiftGraphStore
@testable import FunesNotes

class FakeNoteGraphRevisionManager: NoteGraphRevisionManaging {
    var getResourceState_calledCount = 0
    var getResourceState_error: Error?
    var getResourceState_returnState: GraphConfigurationState?
    func getResourceState() async throws -> GraphConfigurationState {
        getResourceState_calledCount += 1
        
        if let error = getResourceState_error {
            throw error
        } else {
            return getResourceState_returnState!
        }
    }
    
    var getLastRevisionNumber_calledCount = 0
    var getLastRevisionNumber_paramTypes = [GraphStoreRevisioning.Type]()
    var getLastRevisionNumber_paramIds = [NoteId]()
    var getLastRevisionNumber_error: GraphStoreReadError?
    var getLastRevisionNumber_returnAtom: Atom?
    func getLastRevisionNumber<T: GraphStoreRevisioning>(type: T.Type, id: NoteId) async throws -> Atom {
        getLastRevisionNumber_calledCount += 1
        
        getLastRevisionNumber_paramTypes.append(type)
        getLastRevisionNumber_paramIds.append(id)
        
        if let error = getLastRevisionNumber_error {
            throw error
        } else {

            return getLastRevisionNumber_returnAtom!
        }
    }
    
    var getRevision_calledCount = 0
    var getRevision_paramIds = [NoteId]()
    var getRevision_paramRevisions = [Atom]()
    var getRevision_error: GraphStoreReadError?
    var getRevision_returnRevision = [GraphStoreRevisioning]()
    func getRevision<T: GraphStoreRevisioning>(id: NoteId, revision: Atom) async throws -> T {
        getRevision_calledCount += 1
        getRevision_paramIds.append(id)
        getRevision_paramRevisions.append(revision)
        
        if let error = getRevision_error {
            throw error
        } else {
            let returnedRevision = getRevision_returnRevision.first
            getRevision_returnRevision = Array(getRevision_returnRevision.dropFirst())
            return returnedRevision as! T
        }
    }
    
    var saveRevision_calledCount = 0
    var saveRevision_paramRevisions = [GraphStoreRevisioning]()
    var saveRevision_paramRevisionNumbers = [Atom]()
    var saveRevision_error: GraphStoreSaveError?
    func saveRevision<T: GraphStoreRevisioning>(revision: T, revisionNumber: Atom) async throws {
        saveRevision_calledCount += 1
        saveRevision_paramRevisions.append(revision)
        saveRevision_paramRevisionNumbers.append(revisionNumber)
        
        if let error = saveRevision_error {
            throw error
        }
    }
}
