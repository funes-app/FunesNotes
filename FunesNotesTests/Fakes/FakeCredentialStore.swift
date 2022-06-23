import Foundation
import UrsusAtom
@testable import FunesNotes

class FakeCredentialStore: CredentialStoring {
    var shipURL: URL?
    
    var shipCode: PatP?
    
    var saveCredentials_calledCount = 0
    var saveCredentials_paramURL: URL?
    var saveCredentials_paramCode: PatP?
    func saveCredentials(url: URL, code: PatP) {
        saveCredentials_calledCount += 1
        saveCredentials_paramURL = url
        saveCredentials_paramCode = code
    }
    
    var clearCredentials_calledCount = 0
    func clearCredentials() {
        clearCredentials_calledCount += 1
    }
}
