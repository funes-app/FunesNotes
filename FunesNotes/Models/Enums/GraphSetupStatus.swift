import Foundation

enum GraphSetupStatus {
    case ready
    case verifyingGraph
    case creatingGraph
    case creatingRootNode
    case done
}

extension GraphSetupStatus {
    var actionText: String {
        switch self {
        case .ready:
            return ""
        case .verifyingGraph:
            return "Opening notes..."
        case .creatingGraph:
            return "Setting up Graph Store on your ship..."
        case .creatingRootNode:
            return "Creating a graph for notes..."
        case .done:
            return ""
        }
        
    }
}
