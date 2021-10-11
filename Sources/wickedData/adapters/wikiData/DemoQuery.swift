public struct DemoQuery: Query {
    public struct BindingType: Binding {
        let foo: Variable
        let bar: Variable
        let fooLabel: Variable?
        let barLabel: Variable?
        
        static let antiparticleRelationship = Relationship(name: "antiparticleOf")

        public var triples: [Triple] {
            var triples = [
                try! Triple(NodeType.Entity(foo.value), BindingType.antiparticleRelationship, NodeType.Entity(bar.value), type: .source),
                try! Triple(NodeType.Entity(bar.value), BindingType.antiparticleRelationship, NodeType.Entity(foo.value), type: .target)
            ]

            if let fooLabelUnwrapped = fooLabel {
                triples.append(
                    try! Triple(NodeType.Entity(foo.value), BindingType.antiparticleRelationship, NodeType.Literal(fooLabelUnwrapped.value), type: .any)
                )
            }


            if let barLabelUnwrapped = barLabel {
                triples.append(
                    try! Triple(NodeType.Entity(bar.value), labelRelationship, NodeType.Literal(barLabelUnwrapped.value), type: .any)
                )
            }

            return triples
        }
    }

    public let text: String
}

