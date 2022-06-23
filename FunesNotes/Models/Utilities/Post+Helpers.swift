import Foundation
import UrsusHTTP
import SwiftGraphStore

extension Post {
    init(ship: Ship, index: Index, contents: [Content] = []) {
        self.init(author: ship,
                  index: index,
                  timeSent: .now,
                  contents: contents,
                  hash: nil,
                  signatures: [])
    }
}
