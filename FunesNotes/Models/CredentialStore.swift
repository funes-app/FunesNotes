import Foundation
import UrsusAtom
import Valet
import os

typealias ValetCreator = (Identifier, Accessibility) -> ValetSaving

class CredentialStore: CredentialStoring {
    private let logger = Logger()
    
    private(set) var shipURL: URL? {
        get { return userDefaults.url(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }
    
    private(set) var shipCode: PatP? {
        get {
            let codeString: String
            do {
                codeString = try valet.string(forKey: #function)
            } catch KeychainError.itemNotFound {
                logger.debug("+code not found in keychain.  Returning nil")
                return nil
            } catch {
                logger.error("Error retrieving key: \(error.localizedDescription)")
                return nil
            }
            
            let code: PatP
            do {
                code = try PatP(string: codeString)
            } catch {
                logger.error("Invalid key \(codeString), can't decode as PatP")
                return nil
            }
            
            return code
        }
        set {
            guard let codeString = newValue?.string else {
                logger.debug("No value for +code, clearing from keychain")
                do {
                    try valet.removeObject(forKey: #function)
                } catch {
                    logger.error("Exception thrown trying to clear the code from the keychain: \(error.localizedDescription)")
                }
                return
            }
            do {
                try valet.setString(codeString, forKey: #function)
            } catch {
                logger.error("Exception thrown trying to set the code from the keychain: \(error.localizedDescription)")
            }
        }
    }
    
    private let userDefaults: UserDefaults
    private let valet: ValetSaving
    
    init(userDefaults: UserDefaults = .standard,
         valetCreator: ValetCreator = Valet.valet) {
        self.userDefaults = userDefaults
        valet = valetCreator(Identifier(nonEmpty: "Funes Notes")!,
                             .whenUnlocked)

    }
    
    func saveCredentials(url: URL, code: PatP) {
        shipURL = url
        shipCode = code
    }
    
    func clearCredentials() {
        shipURL = nil
        shipCode = nil
    }
}
