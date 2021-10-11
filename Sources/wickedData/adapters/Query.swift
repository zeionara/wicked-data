public protocol Query {
    associatedtype BindingType: Codable

    var text: String { get }
}

