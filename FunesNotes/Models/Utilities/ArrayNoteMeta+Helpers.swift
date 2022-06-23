import Foundation

extension Array where Element == NoteMeta {
    func nextSelectedId(deletedNoteId: NoteId) -> NoteId? {
        if last?.id == deletedNoteId {
            return dropLast()
                .last?
                .id
        }
        
        guard let rowIndex = firstIndex(where: {
            $0.id == deletedNoteId
        }) else { return nil }
        
        return dropFirst(rowIndex + 1)
            .first?
            .id
    }
    
    func ordered() -> [NoteMeta] {
        sorted().reversed()
    }
    
    func nondeleted() -> [NoteMeta] {
        filter { $0.deleted == false }
    }
}
