import Foundation
import UrsusHTTP
@testable import FunesNotes

extension ConnectionStatus: CaseIterable {
    public static var allCases: [ConnectionStatus] {
        [ .notLoggedIn,
          .readyToConnect,
          .loggingIn,
          .openingAirlock,
          .subscribing,
          .connected(ship: Ship.random),

        ]
    }
    
    static var random: ConnectionStatus {
        ConnectionStatus.allCases.randomElement() ?? .loggingIn
    }
}
