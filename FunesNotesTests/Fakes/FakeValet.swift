import Foundation
@testable import FunesNotes

class FakeValet: ValetSaving {
    var string_calledCount = 0
    var string_paramForKey: String?
    var string_returnString: String?
    var string_error: Error?
    func string(forKey: String) throws -> String {
        string_calledCount += 1
        string_paramForKey = forKey
        
        if let error = string_error {
            throw error
        }
        
        return string_returnString!
    }
    
    var setString_calledCount = 0
    var setString_paramString: String?
    var setString_paramKey: String?
    var setString_error: Error?
    func setString(_ string: String, forKey key: String) throws {
        setString_calledCount += 1
        setString_paramString = string
        setString_paramKey = key
        
        if let error = setString_error {
            throw error
        }
    }
    
    var removeObject_calledCount = 0
    var removeObject_paramKey: String?
    var removeObject_error: Error?
    func removeObject(forKey key: String) throws {
        removeObject_calledCount += 1
        removeObject_paramKey = key
        
        if let error = removeObject_error {
            throw error
        }
    }

}
