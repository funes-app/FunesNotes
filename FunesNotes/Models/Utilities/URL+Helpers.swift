import Foundation

extension URL {
    var replacingEmptySchemeWithHTTPS: URL {
        if var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
           components.scheme == nil {
            components.scheme = "https"
            return components.url ?? self
        }
        
        return self
    }
}
