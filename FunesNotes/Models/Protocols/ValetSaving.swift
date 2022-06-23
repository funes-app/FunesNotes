import Foundation
import Valet

protocol ValetSaving {
    func string(forKey: String) throws -> String
    func setString(_ string: String, forKey key: String) throws
    func removeObject(forKey key: String) throws
}

extension Valet: ValetSaving {}
