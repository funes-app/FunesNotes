import Foundation
import SwiftGraphStore

enum GraphStoreIndex {
    case rootNode
    case noteContainer(id: NoteId)
    case noteContentsContainer(id: NoteId)
    case noteContentsRevisionContainer(id: NoteId, revision: Atom)
    case noteContentsRevision(id: NoteId, revision: Atom)
    case noteMetadataContainer(id: NoteId)
    case noteMetadataRevisionContainer(id: NoteId, revision: Atom)
    case noteMetadataRevision(id: NoteId, revision: Atom)
}

extension GraphStoreIndex {
    var indexNumber: Atom? {
        switch self {
        case .noteContentsContainer: fallthrough
        case .noteContentsRevisionContainer: fallthrough
        case .noteContentsRevision:
            return 0
        case .noteMetadataContainer: fallthrough
        case .noteMetadataRevisionContainer: fallthrough
        case .noteMetadataRevision:
            return 1
        default:
            return nil
        }
    }
    
    var revisionNumber: Atom? {
        switch self {
        case let .noteContentsRevisionContainer(_, revision): fallthrough
        case let .noteContentsRevision(_, revision): fallthrough
        case let .noteMetadataRevisionContainer(_, revision): fallthrough
        case let .noteMetadataRevision(_, revision):
            return revision
        default:
            return nil
        }
    }
    
    private var noteIdAtoms: [Atom] {
        switch self {
        case .rootNode:
            return []
        case let .noteContainer(id): fallthrough
        case let .noteContentsContainer(id): fallthrough
        case let .noteContentsRevisionContainer(id, _): fallthrough
        case let .noteContentsRevision(id, _): fallthrough
        case let .noteMetadataContainer(id): fallthrough
        case let .noteMetadataRevisionContainer(id, _): fallthrough
        case let .noteMetadataRevision(id, revision: _):
            guard let noteIdAtom = Atom(id.rawValue) else { return [] }
            return [noteIdAtom]
        }
    }
    
    var index: Index {
        let indexNumberAtoms = [Atom(indexNumber ?? 0)]
        let revisionNumberAtoms = [Atom(revisionNumber ?? 0)]

        let zeroAtom = Atom(0)
        
        let rootAtoms = [zeroAtom]
        let noteContainerAtoms = rootAtoms + noteIdAtoms
        
        let noteContentContainerAtoms = noteContainerAtoms + indexNumberAtoms
        let noteContentRevisionContainerAtoms = noteContentContainerAtoms + revisionNumberAtoms
        let noteContentRevisionAtoms = noteContentRevisionContainerAtoms + [zeroAtom]
        
        let noteMetadataContainerAtoms = noteContainerAtoms + indexNumberAtoms
        let noteMetadataRevisionContainerAtoms = noteMetadataContainerAtoms + revisionNumberAtoms
        let noteMetadataRevisionAtoms = noteMetadataRevisionContainerAtoms + [zeroAtom]

        
        let atoms: [Atom]
        switch self {
        case .rootNode:
            atoms = rootAtoms
        case .noteContainer:
            atoms = noteContainerAtoms
        case .noteContentsContainer:
            atoms = noteContentContainerAtoms
        case .noteContentsRevisionContainer:
            atoms = noteContentRevisionContainerAtoms
        case .noteContentsRevision:
            atoms = noteContentRevisionAtoms
        case .noteMetadataContainer:
            atoms = noteMetadataContainerAtoms
        case .noteMetadataRevisionContainer:
            atoms = noteMetadataRevisionContainerAtoms
        case .noteMetadataRevision:
            atoms = noteMetadataRevisionAtoms
        }
        
        return Index(atoms: atoms)
    }
    
    static func noteId(from index: Index) -> NoteId? {
        guard let value = index.atoms.dropFirst().first else {
            return nil
        }
        
        return NoteId(value)
    }
}
