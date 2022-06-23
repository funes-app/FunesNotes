import Foundation
import UrsusAtom

protocol CredentialStoring {
    var shipURL: URL? { get }
    
    var shipCode: PatP? { get }
    
    func saveCredentials(url: URL, code: PatP)
    func clearCredentials()
}
