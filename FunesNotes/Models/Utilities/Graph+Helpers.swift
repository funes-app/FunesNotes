import Foundation
import UrsusHTTP
import SwiftGraphStore

extension Graph {
    init?(index: SwiftGraphStore.Index,
          post: Post,
          children: Graph? = nil) {
        guard let atom = index.leaf else { return nil }
        let node = Node(post: post, children: children)
        self.init(dictionaryLiteral: (atom, node))        
    }
}
