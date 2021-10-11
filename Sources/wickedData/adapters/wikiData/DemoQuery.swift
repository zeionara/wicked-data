public struct DemoQuery: Query {
    public struct BindingType: Binding {
        let foo: Variable
        let bar: Variable
        let fooLabel: Variable?
        let barLabel: Variable?
        
        static let antiparticleRelationship = Relationship(name: "antiparticleOf")

        public var triples: [Triple] {
            return [
                try! Triple(NodeType.Entity(foo.value), BindingType.antiparticleRelationship, NodeType.Entity(bar.value), type: .train),
                try! Triple(NodeType.Entity(bar.value), BindingType.antiparticleRelationship, NodeType.Entity(foo.value), type: .test)
            ]
        }
    }

    public let text: String
}

