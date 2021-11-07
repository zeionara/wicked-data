import Foundation

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
                try! Triple(BindingType.triplesEntity, BindingType.countRelationship, NodeType.Literal(count.value), type: .source),
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

public protocol CountableBindingTypeWithAggregation: Binding {
    var count: Variable { get }
    var aggregationTriples: [Triple] { get }
    func makeGroupingNode(_ uriSuffix: String?) -> NodeType
}

public extension CountableBindingTypeWithAggregation {
    var triples: [Triple] {
        let aggregationTriples_ = aggregationTriples
        assert(aggregationTriples_.count > 0)
        let firstAggregationTripleTail = aggregationTriples_.first!.tail
        assert(aggregationTriples_.dropFirst().allSatisfy{String(describing: $0.tail) == String(describing: firstAggregationTripleTail)})
        assert(aggregationTriples_.allSatisfy{$0.type == .source})

        return aggregationTriples_ + [
            try! Triple(firstAggregationTripleTail, CountingQuery.BindingType.countRelationship, NodeType.Literal(count.value), type: .source)
        ]
    }

    func makeGroupingNode(_ uriSuffix: String? = nil) -> NodeType {
        let unwrappedUriSuffix = uriSuffix ?? UUID().uuidString
        return NodeType.Entity("https://relentness.nara.zeio/group/\(unwrappedUriSuffix)")
    }
} 

public struct CountingQueryWithAggregation<BindingType: CountableBindingTypeWithAggregation>: Query {
    public typealias BindingType = BindingType

    public let text: String

    public init(text: String) {
        self.text = text
    }
} 

public struct CountableBindingTypeWithOneRelationAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let relation: Variable

    static let groupingRelationRelationship = Relationship(name: "https://relentness.nara.zeio/relation/aggregation/singleRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()
        return [
            try! Triple(NodeType.Entity(relation.value), CountableBindingTypeWithOneRelationAggregation.groupingRelationRelationship, groupNode, type: .source)
        ]
    }
} 

public extension Sample where BindingType: CountableBindingTypeWithAggregation {
    var count: Int {
        count()
    }

    func count(_ relativeThreshold: Double = 0.5) -> Int {
        if results.bindings.count == 0 {
            return 0
        }

        assert(0.0 <= relativeThreshold && relativeThreshold <= 1.0)

        let counts = results.bindings.map{$0.count.value.asInt}.sorted{$0 > $1}
        let absoluteThreshold = Double(counts.first!) * relativeThreshold

        return counts.filter{Double($0) > absoluteThreshold}.reduce(0, +)
    }
}
