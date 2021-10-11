public protocol Binding: Codable {
    var triples: [Triple] { get }
}

let labelRelationship = Relationship(name: "label")

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

public typealias CompressedTriples = (triples: [Triple], id2entity: [String: String], id2relationship: [String: String])

public extension Sample {
    var compressed: CompressedTriples {
        var compressedTriplesArray = [Triple]()
        var entity2id = [String: String]()
        var id2entity = [String: String]()
        var currentEntityId = 0
        var relationship2id = [String: String]()
        var id2relationship = [String: String]()
        var currentRelationshipId = 0

        func makeEntityId(_ entity: NodeType) -> String? {
           var entityId = "\(currentEntityId)" 

           if case .Entity(let value) = entity {
               if let existingEntityId = entity2id[value] {
                   entityId = existingEntityId
               } else {
                   currentEntityId += 1
                   entity2id[value] = entityId
                   id2entity[entityId] = value
               }
           } else {
               return nil
           }

           return entityId
        }

        for triple in triples {
           let headEntityId = makeEntityId(triple.head)
           let tailEntityId = makeEntityId(triple.tail)

           var relationshipId = "\(currentRelationshipId)" 

           if let existingRelationshipId = relationship2id[triple.relationship.name] {
                   relationshipId = existingRelationshipId
           } else {
               currentRelationshipId += 1
               relationship2id[triple.relationship.name] = relationshipId
               id2relationship[relationshipId] = triple.relationship.name
           }

           if let headEntityIdUnwrapped = headEntityId, let tailEntityIdUnwrapped = tailEntityId {
               compressedTriplesArray.append(
                   try! Triple(NodeType.Entity(headEntityIdUnwrapped), Relationship(name: relationshipId), NodeType.Entity(tailEntityIdUnwrapped), type: triple.type)
               )
           }
           // if case .Entity(let value) = triple.head {
           //     if let existingEntityId = entity2id[value] {
           //         entityId = existingEntityId
           //     } else {
           //         currentEntityId += 1
           //         entity2id[value] = entityId
           //         id2entity[entityId] = value
           //     }
           // } else {
           //     continue
           // }
        }

        return CompressedTriples(triples: compressedTriplesArray, id2entity: id2entity, id2relationship: id2relationship)
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

