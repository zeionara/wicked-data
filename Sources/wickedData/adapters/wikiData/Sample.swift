import Foundation
import PcgRandom

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

    public var nBindings: Int {
        return results.bindings.count
    }
}

public enum SampleJoinError: Error {
    case emptyList
}

public func join<BindingType: Binding>(_ samples: [Sample<BindingType>]) throws -> Sample<BindingType> { // TODO: implement as a part of Collection struct extension (see snippet below)
    guard let firstSample = samples.first else {
       throw SampleJoinError.emptyList 
    }

    for sample in samples.dropFirst() {
        assert(sample.head.vars == firstSample.head.vars)
    }

    return Sample<BindingType>(
        head: firstSample.head,
        results: SampleBody<BindingType>(
            bindings: samples.map(\.results.bindings).reduce([], +)
        )
    ) 
}

// public extension Collection where Element == Sample<Binding>  {
//     var joined: [Sample<Element.BindingType>] {
// 
//     }
// }

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
        }

        return CompressedTriples(triples: compressedTriplesArray, id2entity: id2entity, id2relationship: id2relationship)
    }
}

public typealias CVSubset = (train: [Triple], test: [Triple], validation: [Triple], id2entity: [String: String], id2relationship: [String: String])
public extension Sample {
    func cv(validationTargetFraction: Float = 0.2, nFolds: Int = 2, _ handleSubset: (CVSubset) -> Void, shuffle: ([Triple]) -> [Triple]) {
        assert(validationTargetFraction <= 1.0)
        assert(nFolds > 0)

        var seenStringifiedTriples = [String: Triple]()
        var triplesWithoutDuplicates = [Triple]()

        let compressed = self.compressed

        for triple in compressed.triples {
            if let seenTriple = seenStringifiedTriples["\(triple)"] {
                continue
            } else {
                seenStringifiedTriples["\(triple)"] = triple
                triplesWithoutDuplicates.append(triple)
            }
        }

        let sourceTriples = triplesWithoutDuplicates.filter{$0.type == .source}
        let targetTriples = triplesWithoutDuplicates.filter{$0.type == .target}
        
        let nValidationTargetTriples = Int(ceil(validationTargetFraction * Float(targetTriples.count)))
        let nCvTargetTriples = targetTriples.count - nValidationTargetTriples
        //  let nTrainTargetTriples = Int(Float(nFolds - 1) / Float(nFolds) * Float(targetTriples.count - nValidationTargetTriples)
        //  let nTestTargetTriples = Int(ceil(testTargetFraction * Float(targetTriples.count)))

        assert(nCvTargetTriples >= nFolds)
        let nTestTargetTriplesPerFold = Int(floor(Float(nCvTargetTriples) / Float(nFolds)))
        let remainder = nCvTargetTriples - nTestTargetTriplesPerFold * nFolds
        var appendices = [Int]()

        for i in 0..<nFolds {
            appendices.append(i < remainder ? 1 : 0)
        }

        let shuffledSources = shuffle(sourceTriples)
        let shuffledTargets = shuffle(targetTriples)
        var currentTestTargetIndex = 0

        // let trainSubset = shuffledSources + Array(shuffledTargets[nTestTargetTriples..<nTestTargetTriples + nTrainTargetTriples])
        let validationSubset = Array(shuffledTargets[nCvTargetTriples..<shuffledTargets.count])
        for i in 0..<nFolds {
             let nextTestTargetIndex = currentTestTargetIndex + nTestTargetTriplesPerFold + appendices[i]
             // print("0, \(currentTestTargetIndex), \(nextTestTargetIndex), \(shuffledTargets.count)")
             let subset = CVSubset(
                 train: shuffledSources + Array(shuffledTargets[0..<currentTestTargetIndex]) + Array(shuffledTargets[nextTestTargetIndex..<nCvTargetTriples]),
                 test: Array(shuffledTargets[currentTestTargetIndex..<nextTestTargetIndex]),
                 validation: validationSubset,
                 id2entity: compressed.id2entity,
                 id2relationship: compressed.id2relationship
             )
             handleSubset(subset)
             currentTestTargetIndex = nextTestTargetIndex
        }

        // print(nTrainTargetTriples, nTestTargetTriples, nValidationTargetTriples, nTestTargetTriplesPerFold)
    }
    
    func cv(validationTargetFraction: Float = 0.2, nFolds: Int = 2, _ handleSubset: (CVSubset) -> Void) {
        return cv(validationTargetFraction: validationTargetFraction, nFolds: nFolds, handleSubset) { triples in
            triples.shuffled()
        }
    }

    func cv(validationTargetFraction: Float = 0.2, nFolds: Int = 2, seed: Int, handleSubset: (CVSubset) -> Void) {
        var generator = Pcg64Random(seed: UInt64(seed))
        return cv(validationTargetFraction: validationTargetFraction, nFolds: nFolds, handleSubset) { triples in
            let orderingSequence = Double.random(in: 0..<1, using: &generator, n: triples.count)
            return triples.enumerated().sorted{ (lhs, rhs) in
                orderingSequence[rhs.offset] > orderingSequence[lhs.offset]
            }.map{
                $0.element
            } 
        }
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
        case datatype
    }

    public let type: String
    public let value: String
    public let language: String?
    public let datatype: String?
}

