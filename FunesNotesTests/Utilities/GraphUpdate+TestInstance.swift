import Foundation
import UrsusHTTP
import SwiftGraphStore
@testable import FunesNotes

extension GraphStoreUpdate {
    static var testInstance: GraphStoreUpdate {
        GraphStoreUpdate(graphUpdate: GraphUpdate.testInstance)
    }
}

extension GraphUpdate {
    static var testInstance: GraphUpdate {
        Bool.random() ?
            .emptyAddNodes(resource: Resource.testInstance) :
            .addNodesWithEmptyRoot(resource: Resource.testInstance)
    }
    
    static func emptyAddNodes(resource: Resource) -> GraphUpdate {
        .addNodes(resource: resource, nodes: [:])
    }
    
    static func addNodesWithEmptyRoot(resource: Resource) -> GraphUpdate {
        let index = Index("/0")!
        let post = Post(author: resource.ship,
                        index: index,
                        timeSent: Date.now,
                        contents: [],
                        hash: nil,
                        signatures: [])
        
        let graph = Node(post: post, children: nil)
        let nodes = [index: graph]
        return .addNodes(resource: resource, nodes: nodes)
    }
    
    static func updateForRevision<T: GraphStoreRevisioning>(_ revision: T) -> GraphUpdate {
        let index = T.revisionIndex(id: revision.id,
                                    revision: Atom.testInstance)
        let post = Post(author: Ship.testInstance,
                        index: index,
                        timeSent: .now,
                        contents: revision.contents,
                        hash: nil,
                        signatures: [])
        let nodes = [Index.testInstance: Node(post: post, children: nil)]
        return GraphUpdate.addNodes(resource: Resource.testInstance,
                                    nodes: nodes)
    }
}
