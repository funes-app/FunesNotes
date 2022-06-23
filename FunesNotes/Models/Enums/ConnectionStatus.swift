import Foundation
import UrsusHTTP

enum ConnectionStatus {
    case notLoggedIn
    case readyToConnect
    case loggingIn
    case openingAirlock
    case subscribing
    case loggingOut
    case connected(ship: Ship)
}

extension ConnectionStatus: Equatable {}

extension ConnectionStatus {
    var actionText: String {
        switch self {
        case .notLoggedIn:
            return ""
        case .readyToConnect:
            return "Ready to connect..."
        case .loggingIn:
            return "Logging in..."
        case .openingAirlock:
            return "Opening airlock..."
        case .subscribing:
            return "Subscribing to Graph Store..."
        case .loggingOut:
            return "Logging out..."
        case .connected(let ship):
            return "Connected to \(ship.string)"
        }
    }
}
