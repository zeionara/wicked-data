import Foundation

public struct PatternQueryGenerator: Query {
    public typealias BindingType = GeneratedQuery

    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public struct GeneratedQuery: Binding {
    public let query: Variable

    static let patternQueryTextRelation = Relationship(name: "http://relentness.nara.zeio/pattern/query/text")

    public func makePatternNode() -> NodeType {
        NodeType.Entity("https://relentness.nara.zeio/pattern/query/\(UUID().uuidString)")
    }

    public var triples: [Triple] {
        let node = makePatternNode()

        return [
            try! Triple(node, GeneratedQuery.patternQueryTextRelation, NodeType.Literal(query.value), type: .source)
        ]
    }
}

extension Sample where BindingType == GeneratedQuery {
    public var query: String {
        assert(results.bindings.count == 1)

        return results.bindings.first!.query.value
    }
}

