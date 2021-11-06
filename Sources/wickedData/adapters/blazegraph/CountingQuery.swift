public struct CountingQuery: Query {
    public init(text: String) {
        self.text = text
    }

    public struct BindingType: Binding {
        let count: Variable
        
        static let countRelationship = Relationship(name: "count")
        static let triplesEntity = NodeType.Entity("triples")

        public var triples: [Triple] {
            let triples = [
                try! Triple(BindingType.triplesEntity, BindingType.countRelationship, NodeType.Entity(count.value), type: .source),
            ]

            return triples
        }
    }

    public let text: String
}

public extension Sample where BindingType == CountingQuery.BindingType {
    var count: Int {
        self.results.bindings.count > 0 ? self.results.bindings.first!.count.value.asInt : 0
    }
}

