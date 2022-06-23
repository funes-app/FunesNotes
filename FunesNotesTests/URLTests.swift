import XCTest
@testable import FunesNotes

class URLTests: XCTestCase {

    func test_replacingEmptySchemeWithHTTPS_whenSchemePresent_noChange() {
        let url = URL(string: "ftp://funes.app")!
        
        XCTAssertEqual(url.replacingEmptySchemeWithHTTPS, url)
    }
    func test_replacingEmptySchemeWithHTTPS_whenSchemeIsEmpty_usesHTTPS() {
        let url = URL(string: "funes.app")!
        
        let expectedURL = URL(string: "https:funes.app")!
        XCTAssertEqual(url.replacingEmptySchemeWithHTTPS, expectedURL)
    }
}
