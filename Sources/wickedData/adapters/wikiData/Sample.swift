public protocol Binding: Codable {
    var triples: [Triple] { get }
}

public struct Sample<BindingType: Binding>: Codable {
    let head: SampleHead
    let results: SampleBody<BindingType>

    public var triples: [Triple] {
        var triples = [Triple]()

        for binding in results.bindings {
            triples += binding.triples
        }
        
        return triples
    }
}

public struct SampleHead: Codable {
    let vars: [String]
}

public struct SampleBody<BindingType: Binding>: Codable {
    let bindings: [BindingType]
}

public struct Variable: Codable {
    enum CodingKeys: String, CodingKey {
        case language = "xml:lang"
        case type
        case value
    }

    let type: String
    let value: String
    let language: String?
}

