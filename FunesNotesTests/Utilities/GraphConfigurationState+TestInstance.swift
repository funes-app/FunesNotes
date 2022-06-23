import Foundation
@testable import FunesNotes

extension GraphConfigurationState: CaseIterable {
    public static var allCases: [GraphConfigurationState] {
        return [
            .configured,
            .missingGraph,
            .missingRootNode
        ]
    }
    
    static var testInstance: GraphConfigurationState {
        return allCases.randomElement()!
    }
}
