import XCTest
import SwiftGraphStore

@testable import FunesNotes

class GraphStoreIndexTests: XCTestCase {

    func test_index() {
        let root = Atom(0)
        
        let contentsNumber = Atom(0)
        let metadataNumber = Atom(1)
        
        for graphStoreIndex in GraphStoreIndex.allCases {
            switch graphStoreIndex {
            case .rootNode:
                let expectedIndexAtoms = [root]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))
                
            case let .noteContainer(id):
                let expectedIndexAtoms = [root, noteIdAsAtom(id)]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))

            case let .noteContentsContainer(id):
                let expectedIndexAtoms = [root, noteIdAsAtom(id), contentsNumber]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))

            case let .noteContentsRevisionContainer(id, revision):
                let expectedIndexAtoms = [root, noteIdAsAtom(id), contentsNumber, revision]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))

            case let .noteContentsRevision(id, revision):
                let expectedIndexAtoms = [root, noteIdAsAtom(id), contentsNumber, revision, Atom(0)]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))

            case let .noteMetadataContainer(id):
                let expectedIndexAtoms = [root, noteIdAsAtom(id), metadataNumber]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))

            case let .noteMetadataRevisionContainer(id, revision):
                let expectedIndexAtoms = [root, noteIdAsAtom(id), metadataNumber, revision]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))
                
            case let .noteMetadataRevision(id, revision):
                let expectedIndexAtoms = [root, noteIdAsAtom(id), metadataNumber, revision, Atom(0)]
                XCTAssertEqual(graphStoreIndex.index, Index(atoms: expectedIndexAtoms))
            }
        }
    }
    
    private func noteIdAsAtom(_ id: NoteId) -> Atom {
        Atom(id.rawValue)!
    }
    
    func test_noteId_usesSecondIndexAtom() {
        let noteIdAtom = Atom.testInstance
        let expectedId = NoteId(noteIdAtom)
        let atoms = [Atom(0), noteIdAtom] + Index.testInstance.atoms
        let index = Index(atoms: atoms)
        
        XCTAssertEqual(GraphStoreIndex.noteId(from: index), expectedId)
    }
    
    func test_noteIndex_whenNoSecondAtom_returnsNil() {
        let atoms = [Atom(0)]
        let index = Index(atoms: atoms)
        
        XCTAssertNil(GraphStoreIndex.noteId(from: index))
    }
}

extension GraphStoreIndex: CaseIterable {
    public static var allCases: [GraphStoreIndex] {
        [
            .rootNode,
            .noteContainer(id: NoteId.testInstance),
            .noteContentsContainer(id: NoteId.testInstance),
            .noteContentsRevisionContainer(id: NoteId.testInstance,
                                           revision: Atom.testInstance),
            .noteContentsRevision(id: NoteId.testInstance,
                                  revision: Atom.testInstance),
            .noteMetadataContainer(id: NoteId.testInstance),
            .noteMetadataRevisionContainer(id: NoteId.testInstance, revision: Atom.testInstance),
            .noteMetadataRevision(id: NoteId.testInstance, revision: Atom.testInstance)


        ]
    }
}
