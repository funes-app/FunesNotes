import Foundation
import UrsusAtom

class LoginViewModel: ObservableObject {
    enum ConnectError: LocalizedError {
        case missingURL
        case missingKey
        case invalidURL
        case invalidKey
        
        public var errorDescription: String? {
            switch self {
            case .missingURL:
                return "Please enter the URL you use to connect to your ship"
            case .missingKey:
                return "Please enter your access key"
            case .invalidURL:
                return "This is not a valid URL.  Please try again!"
            case .invalidKey:
                return "This is not a valid key.  Please try again!"
            }
        }
    }
    
    enum Field {
        case url
        case key
    }

    @Published var url: String = ""
    @Published var key: String = ""
    
    var urlAsURL: URL? {
        guard let url = URL(string: url.trimmingCharacters(in: .whitespaces)),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.path = ""
        
        return components.url
    }
    
    var keyAsPatP: PatP? {
        do {
            return try PatP(string: key.trimmingCharacters(in: .whitespaces))
        } catch {
            return nil
        }
    }
    
    @Published var focusedField: Field?
    
    @Published var isPasswordSecure = true
    
    var connectError: ConnectError?
    @Published var showConnectError = false
    
    func validateFields() -> Bool {
        guard !url.isEmpty else {
            setConnectError(.missingURL)
            focusedField = .url
            return false
        }
        
        guard validateURL() else {
            setConnectError(.invalidURL)
            focusedField = .url
            return false
        }
        
        guard !key.isEmpty else {
            setConnectError(.missingKey)
            focusedField = .key
            return false
        }
        
        guard validateKey() else {
            setConnectError(.invalidKey)
            focusedField = .key
            return false
        }

        return true
    }
    
    private func validateURL() -> Bool {
        return urlAsURL != nil
    }

    private func validateKey() -> Bool {
        return keyAsPatP != nil
    }
    
    private func setConnectError(_ error: ConnectError) {
        connectError = error
        showConnectError = true
    }
}
