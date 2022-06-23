import Foundation
import XCTest
import Combine
import SwiftGraphStore

extension XCTestCase {
    func waitForResult<T>(_ publisher: AnyPublisher<T, Never>,
                          action: () async -> Void = {}) async throws -> T {
        var result: T?
        let expectation = expectation(description: "Awaiting publisher")
        let cancellable = publisher
            .sink(receiveValue: { t in
                result = t
                expectation.fulfill()
            })
        
        await action()
                
        await waitForExpectations(timeout: 1)
        cancellable.cancel()
        
        return try XCTUnwrap(result)
    }
    
    func waitForNoResult<T>(_ publisher: AnyPublisher<T, Never>,
                         action: () -> Void = {}) async throws {
        let expectation = expectation(description: "Awaiting publisher")
        expectation.isInverted = true
        
        let cancellable = publisher
            .sink(receiveValue: { value in
                XCTFail("Unexpected value: \(value)!")
                expectation.fulfill()
            })
        
        action()

        await waitForExpectations(timeout: 0.1)
        cancellable.cancel()
    }
    
    func waitForNoResult<T>(_ publisher: AnyPublisher<T, Never>,
                         action: () async throws -> Void = {}) async throws {
        let expectation = expectation(description: "Awaiting publisher")
        expectation.isInverted = true
        
        let cancellable = publisher
            .sink(receiveValue: { value in
                XCTFail("Unexpected value: \(value)!")
                expectation.fulfill()
            })
        
        try await action()

        await waitForExpectations(timeout: 0.1)
        cancellable.cancel()
    }
    
    func verifyAsyncErrorThrown(action: () async throws -> Void,
                                verifyError: (Error) -> Void) async throws {
        do {
            try await action()
            XCTFail("This should have thrown")
        } catch {
            verifyError(error)
        }
    }
    
    func XCTAssertEqualPosts(_ post1: Post?, _ post2: Post?) {
        if post1 == nil && post2 == nil { return }
        
        guard let post1 = post1,
        let post2 = post2 else {
            XCTFail("Posts should both be nil or neither should be nil")
            return
        }

        XCTAssertEqual(post1.author, post2.author)
        XCTAssertEqual(post1.index, post2.index)
        XCTAssertEqualDates(post1.timeSent, post2.timeSent)
        XCTAssertEqual(post1.contents, post2.contents)
        XCTAssertEqual(post1.hash, post2.hash)
        XCTAssertEqual(post1.signatures, post2.signatures)
    }
    
    func XCTAssertEqualDates(_ date1: Date, _ date2: Date) {
        XCTAssertEqual(date1.timeIntervalSinceReferenceDate,
                       date2.timeIntervalSinceReferenceDate,
                       accuracy: 10)
    }
}
