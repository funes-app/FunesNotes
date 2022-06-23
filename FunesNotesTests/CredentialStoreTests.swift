import XCTest
import UrsusAtom
import Valet
@testable import FunesNotes

class CredentialStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    
    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
    }

    func test_init_createsValet() throws {
        var valetCreator_identifier: Identifier?
        var valetCreator_accessibility: Accessibility?
        func valetCreator(identifier: Identifier,
                          accessibility: Accessibility) -> ValetSaving {
            
            valetCreator_identifier = identifier
            valetCreator_accessibility = accessibility
            
            return FakeValet()
        }
        
        let _ = CredentialStore(userDefaults: userDefaults,
                                valetCreator: valetCreator)
        
        let identifier = try XCTUnwrap(valetCreator_identifier)
        XCTAssertEqual(identifier.description, Identifier(nonEmpty: "Funes Notes")?.description)
        
        let accessibility = try XCTUnwrap(valetCreator_accessibility)
        XCTAssertEqual(accessibility, .whenUnlocked)
    }
    
    func test_shipURL_readsFromCorrectKey() {
        let expectedURL = URL(string: "http://funes.app")!
        userDefaults.set(expectedURL, forKey: "shipURL")
        
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator())
        XCTAssertEqual(testObject.shipURL, expectedURL)
    }
    
    func test_shipURL_whenItemNotFoundReturnsNil() {
        let expectedURL = URL(string: "http://funes.app")!
        userDefaults.set(expectedURL, forKey: "shipURL")
        
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator())
        XCTAssertEqual(testObject.shipURL, expectedURL)
    }
    
    func test_urbitShipCode_readsFromValet() {
        let expectedCode = PatP.random
        let valet = FakeValet()
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator(valet))
        valet.string_returnString = expectedCode.string
        XCTAssertEqual(testObject.shipCode, expectedCode)
    }
    
    func test_urbitShipCode_whenCodeNotFound_returnsNil() {
        let valet = FakeValet()
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator(valet))
        
        valet.string_error = KeychainError.itemNotFound
        XCTAssertNil(testObject.shipCode)
    }
    
    func test_urbitShipCode_whenCodeNotValidPatP_returnsNil() {
        let valet = FakeValet()
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator(valet))
        
        valet.string_returnString = "This is not a @p"
        XCTAssertNil(testObject.shipCode)
    }

    func test_saveCredentials_writesURLToCorrectKeyInUserDefaults() {
        let expectedURL = URL(string: "https://urbit.org")!

        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator())
        testObject.saveCredentials(url: expectedURL, code: PatP.random)
        XCTAssertEqual(userDefaults.url(forKey: "shipURL"),
                       expectedURL)
    }
    
    func test_saveCredentials_savesCodeToValet() {
        let valet = FakeValet()
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator(valet))
        
        let expectedCode = PatP.random
        testObject.saveCredentials(url: URL(string: "funes.app")!, code: expectedCode)
        
        XCTAssertEqual(valet.setString_calledCount, 1)
        XCTAssertEqual(valet.setString_paramString, expectedCode.string)
        XCTAssertEqual(valet.setString_paramKey, "shipCode")
    }
    
    func test_clearCredentials_clearsURLAndCode() {
        let valet = FakeValet()
        let testObject = CredentialStore(userDefaults: userDefaults,
                                         valetCreator: valetCreatorCreator(valet))
        
        testObject.clearCredentials()
        
        XCTAssertNil(userDefaults.url(forKey: "shipURL"))
        XCTAssertEqual(valet.removeObject_calledCount, 1)
        XCTAssertEqual(valet.removeObject_paramKey, "shipCode")
    }
    
    private func valetCreatorCreator(_ valet: FakeValet = FakeValet()) -> ValetCreator {
        valet.string_returnString = PatP.random.string
        return { (_: Identifier, _: Accessibility) -> ValetSaving in
            valet
        }
    }
}
