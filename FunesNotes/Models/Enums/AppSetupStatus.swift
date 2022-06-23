import Foundation

enum AppSetupStatus {
    case notLoggedIn
    case readyToConnect
    case connecting(ConnectionStatus)
    case settingUpGraph(GraphSetupStatus)
    case synchronizing(SynchronizerSetupStatus)
    case setupComplete
}

extension AppSetupStatus: Equatable {}

extension AppSetupStatus {
    var actionText: String {
        switch self {
        case .notLoggedIn:
            return ""
        case .readyToConnect:
            return "Ready to connect..."
        case .connecting(let connectionStatus):
            return connectionStatus.actionText
        case .settingUpGraph(let graphSetupStatus):
            return graphSetupStatus.actionText
        case .synchronizing(let synchronizerStatus):
            return synchronizerStatus.actionText
        case .setupComplete:
            return "Finished!"
        }
        
    }
}
