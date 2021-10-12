import XCTest
import PcgRandom
@testable import wickedData

final class wickedDataTests: XCTestCase {
    func testExample() throws {
        let adapter = WikiDataAdapter(address: "query.wikidata.org", port: 80)
        XCTAssertEqual(adapter.url, "http://query.wikidata.org:80")
        let query = """
        SELECT DISTINCT ?foo ?bar WHERE 
        {
          ?foo wdt:P2152 ?bar.
          SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        }
        LIMIT 2
        """

        let queryWithLabels = """
        SELECT DISTINCT ?foo ?fooLabel ?bar ?barLabel WHERE 
        {
          ?foo wdt:P2152 ?bar.
          filter (?foo != ?bar).
          SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        }
        LIMIT 7
        """

        BlockingTask {
            let sample = try! await adapter.sample(DemoQuery(text: query))
            XCTAssertEqual(sample.results.bindings.count, 2)

            let sampleWithLabels = try! await adapter.sample(DemoQuery(text: queryWithLabels))
            XCTAssertEqual(sampleWithLabels.results.bindings.count, 7)

            _ = sampleWithLabels.results.bindings.map{ binding in
                print("\(binding.fooLabel?.value ?? " - ") is the antiparticle of \(binding.barLabel?.value ?? " - ")")
            }

            for triple in sampleWithLabels.triples {
                print(triple)
            }

            print(sampleWithLabels.compressed)

            // let seed = 18
            // var generator = Pcg64Random(seed: UInt64(seed))
            // sampleWithLabels.cv{ subset in
            //     print(subset)
            // } shuffle: { triples in
            //     let orderingSequence = Double.random(in: 0..<1, using: &generator, n: triples.count)
            //     return triples.enumerated().sorted{ (lhs, rhs) in
            //         orderingSequence[rhs.offset] > orderingSequence[lhs.offset]
            //     }.map{
            //         $0.element
            //     } 
            //     // return triples.shuffled()
            // }

            sampleWithLabels.cv(seed: 17) { subset in
                print(subset)
            }
        }
    }
}
