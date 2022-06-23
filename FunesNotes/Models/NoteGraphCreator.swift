import Foundation
import UrsusHTTP
import SwiftGraphStore

struct NoteGraphCreator: NoteGraphCreating {
    func newPostAndChildren(resource: Resource,
                            contents: NoteContents,
                            metadata: NoteMeta) -> (Post, Graph) {
        let revision: Atom = 0
        let contentRevisionGraph = contents
            .makeRevisionGraph(ship: resource.ship,
                               revision: revision)
        
        let contentRevisionContainerIndex = GraphStoreIndex
            .noteContentsRevisionContainer(id: contents.id, revision: revision)
            .index
        let contentRevisionContainerGraph = makeGraph(ship: resource.ship,
                                                      index: contentRevisionContainerIndex,
                                                      children: contentRevisionGraph)
         
        let contentsContainerIndex = GraphStoreIndex
            .noteContentsContainer(id: contents.id)
            .index
        let contentsContainerGraph = makeGraph(ship: resource.ship,
                                              index: contentsContainerIndex,
                                              children: contentRevisionContainerGraph)
        
        let metaRevisionGraph = metadata
            .makeRevisionGraph(ship: resource.ship, revision: revision)
        
        let metaRevisionContainerIndex = GraphStoreIndex
            .noteMetadataRevisionContainer(id: contents.id, revision: revision)
            .index
        let metaRevisionContainerGraph = makeGraph(ship: resource.ship,
                                                   index: metaRevisionContainerIndex,
                                                   children: metaRevisionGraph)
        
        let metaContainerIndex = GraphStoreIndex
            .noteMetadataContainer(id: contents.id)
            .index
        let metaContainerGraph = makeGraph(ship: resource.ship,
                                           index: metaContainerIndex,
                                           children: metaRevisionContainerGraph)
        
        let noteContainerIndex = GraphStoreIndex
            .noteContainer(id: contents.id)
            .index
        let noteContainerPost = Post(ship: resource.ship,
                                     index: noteContainerIndex)
        
        let children = contentsContainerGraph
            .merging(metaContainerGraph) { (c, _) in c}
        
        return (noteContainerPost, children)
    }
    
    private func makeGraph(ship: Ship,
                           index: Index,
                           children: Graph?,
                           contents: [Content] = []) -> Graph {
        let post = Post(ship: ship,
                        index: index,
                        contents: contents)
        return Graph(index: index, post: post, children: children)!
    }
}
