public protocol GraphServiceAdapter {
    var address: String { get }
    var port: Int { get }
}

public enum GraphServiceAdapterError: Error {
    case invalidUrl(_ url: String)
}

public extension GraphServiceAdapter {
    var url: String {
        "http://\(address):\(port)"
    }
}

