import Foundation
import UrsusHTTP
import SwiftGraphStore
import os

struct NoteGraphRevisionManager: NoteGraphRevisionManaging {
    private let resource: Resource
    private let graphStoreInterface: GraphStoreAsyncInterfacing
    
    private let logger = Logger()

    init(resource: Resource,
         graphStoreInterface: GraphStoreAsyncInterfacing) {
        self.resource = resource
        self.graphStoreInterface = graphStoreInterface
    }
    
    func getResourceState() async throws -> GraphConfigurationState {
        do {
            let graphStoreUpdate = try await graphStoreInterface.readRootNodes(resource: resource)

            guard case let .addNodes(_, nodes) = graphStoreUpdate.graphUpdate else {
                throw GraphStoreReadError.invalidResponse(update: graphStoreUpdate.graphUpdate)
            }

            return nodes.keys.count > 0 ? .configured : .missingRootNode
        } catch let error as ScryError {
            if case .resourceNotFound = error {
                return .missingGraph
            }
            let readError = GraphStoreReadError.readFailure(error: error)
            throw readError
        }
    }
    
    func getLastRevisionNumber<T: GraphStoreRevisioning>(type: T.Type, id: NoteId) async throws -> Atom {
    
        let containerIndex = T.containerIndex(id: id)
        do {

            let revisionsUpdate = try await graphStoreInterface
                .readChildren(resource: resource,
                              index: containerIndex,
                              mode: .excludeDescendants)
                .graphUpdate
            
            guard let leaf = try getHighestRevisionIndex(revisionsUpdate: revisionsUpdate).leaf else {
                logger.info("This index was an empty list!")
                throw GraphStoreReadError.invalidResponse(update: revisionsUpdate)
            }

            return leaf
        } catch ScryError.resourceNotFound {
            logger.info("Can't find revisions for id: \(id)")
            
            throw GraphStoreReadError.notFound(resource: resource,
                                               index: containerIndex)
        } catch let error as ScryError {
            throw GraphStoreReadError.readFailure(error: error)
        }
    }
    
    func getRevision<T: GraphStoreRevisioning>(id: NoteId, revision: Atom) async throws -> T {
        
        let index = T.revisionIndex(id: id, revision: revision)
        do {
            let update = try await graphStoreInterface
                .readNode(resource: resource,
                          index: index,
                          mode: .includeDescendants)
                .graphUpdate
            
            let post = try getPost(graphUpdate: update)
            
            guard let contents = post.contents.first else {
                logger.error("Post at \(post.index) was missing contents")
                throw GraphStoreReadError.invalidResponse(update: nil)
            }
            
            guard let data = contents.text.data(using: .utf8),
                  let revision = try? JSONDecoder().decode(T.self, from: data) else {
                logger.error("Post at \(post.index) has invalid contents: \(contents.text)")
                throw GraphStoreReadError.invalidResponse(update: nil)
            }
            
            return revision

        } catch ScryError.resourceNotFound {
            logger.info("Can't find revisions for id: \(id)")
            
            throw GraphStoreReadError.notFound(resource: resource,
                                               index: index)
        } catch let error as ScryError {
            logger.info("Error downloading revision \(revision) for id \(id): \(error.localizedDescription)")

            throw GraphStoreReadError.readFailure(error: error)
        }
    }
    
    func saveRevision<T: GraphStoreRevisioning>(revision: T, revisionNumber: Atom) async throws {
        let contentGraph = revision.makeRevisionGraph(ship: resource.ship,
                                                      revision: revisionNumber)
        
        let revisionContainerIndex = T.revisionContainerIndex(id: revision.id, revision: revisionNumber)
        let containerPost = Post(ship: resource.ship,
                                 index: revisionContainerIndex)
        do {
            try await graphStoreInterface.addNode(resource: resource,
                                                  post: containerPost,
                                                  children: contentGraph)
        } catch let error as PokeError {
            throw GraphStoreSaveError.saveFailure(error: error)
        }
    }
    
    private func getHighestRevisionIndex(revisionsUpdate: GraphUpdate) throws -> Index {
        let nodes = try getNodes(graphUpdate: revisionsUpdate)
        
        guard let lastKey = nodes.keys.sorted().last else {
            logger.info("I couldn't read any revisions in this graph!")
            throw GraphStoreReadError.invalidResponse(update: revisionsUpdate)
        }
        return lastKey
    }
    
    private func getNodes(graphUpdate: GraphUpdate) throws -> [Index: Node] {
        guard case let .addNodes(_, nodes) = graphUpdate else {
            logger.info("Ship did not return an 'addNodes' response!")
            throw GraphStoreReadError.invalidResponse(update: graphUpdate)
        }
        return nodes
    }
    
    private func getPost(graphUpdate: GraphUpdate) throws -> Post {
        let nodes = try getNodes(graphUpdate: graphUpdate)
        
        guard let graph = nodes.values.first else {
            logger.info("Response nodes didn't have any values")
            throw GraphStoreReadError.invalidResponse(update: graphUpdate)
        }
        
        return graph.post
    }
}
