import SwiftUI

@main
struct FunesNotesApp: App {
    let fileConnector = FileConnector()
    let shipSession = ShipSession()
    
    var body: some Scene {
        WindowGroup {
            ContentView(fileConnector: fileConnector,
                        shipSession: shipSession)
        }
    }
}
