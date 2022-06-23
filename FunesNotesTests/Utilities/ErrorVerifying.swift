import Foundation
import UrsusHTTP
import SwiftGraphStore
import XCTest
@testable import FunesNotes

protocol ErrorVerifying {
    func verifyReadError(error: Error, scryError: ScryError)
    func verifySaveError(error: Error, pokeError: PokeError)
    func verifyCreateGraphFailure(error: Error,
                                  resource: Resource,
                                  pokeError: PokeError)
    func verifyInvalidResponse(error: Error)
    func verifyNotFound(error: Error)
    func verifyGraphStoreVersionIsNewer(error: Error, lastModified: Date)
}

extension ErrorVerifying {
    func verifyReadError(error: Error, scryError: ScryError) {
        guard let graphStoreReadError = error as? GraphStoreReadError,
              case .readFailure(let internalError) = graphStoreReadError else {
                  XCTFail("Invalid error type: \(error)")
                  return
              }
        XCTAssertEqual(internalError.errorDescription,
                       scryError.errorDescription)
    }
    
    func verifySaveError(error: Error, pokeError: PokeError) {
        guard let graphStoreSaveError = error as? GraphStoreSaveError,
              case .saveFailure(let internalError) = graphStoreSaveError else {
                  XCTFail("Invalid error type: \(error)")
                  return
              }
        XCTAssertEqual(internalError.errorDescription,
                       pokeError.errorDescription)
    }
    
    func verifyInvalidResponse(error: Error) {
        guard let graphStoreReadError = error as? GraphStoreReadError,
              case .invalidResponse = graphStoreReadError else {
                  XCTFail("Invalid error type: \(error)")
                  return
              }
    }
    
    func verifyNotFound(error: Error) {
        guard let graphStoreReadError = error as? GraphStoreReadError,
              case .notFound = graphStoreReadError else {
                  XCTFail("Invalid error type: \(error)")
                  return
              }
    }
    
    func verifyGraphStoreVersionIsNewer(error: Error, lastModified: Date) {
        guard let graphStoreSaveError = error as? GraphStoreSaveError,
              case .graphStoreVersionIsNewer(let errorLastModified) = graphStoreSaveError else {
                  XCTFail("Invalid error type: \(error)")
                  return
              }
        
        XCTAssertEqual(errorLastModified, lastModified)
    }
    
    func verifyCreateGraphFailure(error: Error,
                                  resource: Resource,
                                  pokeError: PokeError) {
        guard let graphStoreSaveError = error as? GraphStoreSaveError,
              case let .createGraphFailure(errorResource, internalError) = graphStoreSaveError else {
                  XCTFail("Invalid error type: \(error)")
                  return
              }
        XCTAssertEqual(errorResource, resource)
        XCTAssertEqual(internalError.errorDescription,
                       pokeError.errorDescription)
    }
}
