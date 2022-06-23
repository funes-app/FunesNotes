import Foundation

enum NoteFileError: LocalizedError {
    case saveFailure(error: Error)
    case loadFailure(error: Error)
    case deleteFailure(error: Error)
    
    public var errorDescription: String? {
        internalError.localizedDescription
    }
    
    var internalError: NSError {
        switch self {
        case .saveFailure(let error):
            return error as NSError
        case .loadFailure(let error):
            return error as NSError
        case .deleteFailure(let error):
            return error as NSError
        }
    }
}
