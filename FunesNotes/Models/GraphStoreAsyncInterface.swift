import Foundation
import Combine
import UrsusHTTP
import SwiftGraphStore
import os

class GraphStoreAsyncInterface: GraphStoreAsyncInterfacing {
    let graphStoreConnection: GraphStoreConnecting
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    init(graphStoreConnection: GraphStoreConnecting) {
        self.graphStoreConnection = graphStoreConnection
    }
    
    func login() async throws -> Ship {
        return try await withCheckedThrowingContinuation { continuation in
            
            graphStoreConnection
                .requestLogin()
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { ship in
                    continuation.resume(returning: ship)
                })
                .store(in: &cancellables)
        }
    }
    
    func connect() async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestConnect()
                .sink { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(with: .success(Void()))
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
    
    func startSubscription() async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestStartSubscription()
                .sink { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(with: .success(Void()))
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
    
    func readRootNodes(resource: Resource) async throws -> GraphStoreUpdate {
        return try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestReadRootNodes(resource: resource)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { update in
                    continuation.resume(returning: update)
                })
                .store(in: &cancellables)
        }
    }
    
    func readNode(resource: Resource, index: Index, mode: ScryMode) async throws -> GraphStoreUpdate {
        return try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestReadNode(resource: resource,
                                 index: index,
                                 mode: mode)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { update in
                    continuation.resume(returning: update)
                })
                .store(in: &cancellables)
        }
    }
    
    func readChildren(resource: Resource, index: Index, mode: ScryMode) async throws -> GraphStoreUpdate {
        return try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestReadChildren(resource: resource,
                                     index: index,
                                     mode: mode)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { update in
                    continuation.resume(returning: update)
                })
                .store(in: &cancellables)
        }
    }
    
    func createGraph(resource: Resource) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestAddGraph(resource: resource)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(with: .success(Void()))
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }
    
    func addNode(resource: Resource, post: Post, children: Graph?) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            graphStoreConnection
                .requestAddNodes(resource: resource,
                                 post: post,
                                 children: children)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(with: .success(Void()))
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }
}
