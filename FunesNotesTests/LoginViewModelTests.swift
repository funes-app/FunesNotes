import XCTest
import UrsusAtom
@testable import FunesNotes

class LoginViewModelTests: XCTestCase {
    
    func test_doesNotRetain() {
        var testObject: LoginViewModel? = LoginViewModel()
        
        weak var weakTestObject = testObject
        testObject = nil
        XCTAssertNil(weakTestObject)
    }
    
    func test_urlAsUrl_whenValid_returnsURL() throws {
        let url = "https://funes.app"
                
        let testObject = LoginViewModel()
        testObject.url = url
        
        let expectedURL = URL(string: url)
        XCTAssertEqual(testObject.urlAsURL, expectedURL)
    }
    
    func test_urlAsURL_whenInvalid_returnsNil() throws {
        let url = ""
                
        let testObject = LoginViewModel()
        testObject.url = url
        
        XCTAssertNil(testObject.urlAsURL)
    }
    
    func test_keyAsPatP_whenValid_returnsPatP() throws {
        let key = "sampel-palnet"
                
        let testObject = LoginViewModel()
        testObject.key = key
        
        let expectedPatP = try PatP(string: key)
        XCTAssertEqual(testObject.keyAsPatP, expectedPatP)
    }
    
    func test_keyAsPatP_trimsWhitespace() throws {
        let key = "   \t  sampel-palnet\t  "
                
        let testObject = LoginViewModel()
        testObject.key = key
        
        let expectedPatP = try PatP(string: "sampel-palnet")
        XCTAssertEqual(testObject.keyAsPatP, expectedPatP)
    }
    
    func test_keyAsPatP_whenInvalid_returnsNil() throws {
        let key = "not a valid patp"
                
        let testObject = LoginViewModel()
        testObject.key = key
        
        XCTAssertNil(testObject.keyAsPatP)
    }
    
    func test_validateFields_whenURLIsEmpty_errorsAndSetsFocus() {
        let testObject = LoginViewModel()
        
        testObject.url = ""
        testObject.key = ""
        
        let isValid = testObject.validateFields()
        
        XCTAssertEqual(isValid, false)
        
        XCTAssertEqual(testObject.connectError, LoginViewModel.ConnectError.missingURL)
        XCTAssertEqual(testObject.showConnectError, true)
        XCTAssertEqual(testObject.focusedField, LoginViewModel.Field.url)
    }
    
    func test_validateFields_whenURLIsInvalid_errorsAndSetsFocus() {
        let testObject = LoginViewModel()
        
        testObject.url = "🌮🌯"
        testObject.key = ""
        
        let isValid = testObject.validateFields()
        
        XCTAssertEqual(isValid, false)
        
        XCTAssertEqual(testObject.connectError, LoginViewModel.ConnectError.invalidURL)
        XCTAssertEqual(testObject.showConnectError, true)
        XCTAssertEqual(testObject.focusedField, LoginViewModel.Field.url)
    }
    
    func test_validateFields_whenKeyIsEmpty_errorsAndSetsFocus() {
        let testObject = LoginViewModel()
        
        testObject.url = "http://localhost"
        testObject.key = ""
        
        let isValid = testObject.validateFields()
        
        XCTAssertEqual(isValid, false)

        XCTAssertEqual(testObject.connectError, LoginViewModel.ConnectError.missingKey)
        XCTAssertEqual(testObject.showConnectError, true)
        XCTAssertEqual(testObject.focusedField, LoginViewModel.Field.key)
    }
    
    func test_validateFields_whenKeyIsInvalid_errorsAndSetsFocus() {
        let testObject = LoginViewModel()
        
        testObject.url = "http://localhost"
        testObject.key = "this is not a valid @p"
        
        let isValid = testObject.validateFields()
        
        XCTAssertEqual(isValid, false)

        XCTAssertEqual(testObject.connectError, LoginViewModel.ConnectError.invalidKey)
        XCTAssertEqual(testObject.showConnectError, true)
        XCTAssertEqual(testObject.focusedField, LoginViewModel.Field.key)
    }
    
    func test_validateFields_whenFieldsValid_returnsTrue() {
        let testObject = LoginViewModel()
        
        testObject.url = "http://sampel-palnet.io"
        testObject.key = PatP.random.string
        
        let isValid = testObject.validateFields()
        
        XCTAssertEqual(isValid, true)

        XCTAssertNil(testObject.connectError)
        XCTAssertEqual(testObject.showConnectError, false)
        XCTAssertNil(testObject.focusedField)
    }
}
