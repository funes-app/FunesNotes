import Foundation


struct NoteListRowViewModel {
    private let emptyTitle = "New Note"
    
    func title(noteMeta: NoteMeta) -> String {
        if let title = noteMeta.title,
           !title.isEmpty {
            return title
        } else {
            return emptyTitle
        }        
    }
    
    func subtitle(noteMeta: NoteMeta) -> String {
        noteMeta.subtitle ?? ""
    }
    
    func lastModifiedDescription(noteMeta: NoteMeta) -> String {
        lastModifiedDescription(noteMeta: noteMeta, now: Date.now)
    }
    
    internal func lastModifiedDescription(noteMeta: NoteMeta,
                                          now: Date) -> String {
        let formatter = DateFormatter()
        if (noteMeta.contentsLastModified.onSameDayAs(now)) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: noteMeta.contentsLastModified)
    }
}
        
fileprivate extension Date {
    func onSameDayAs(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.startOfDay(for: self) == cal.startOfDay(for: date)
    }
}
        
        
