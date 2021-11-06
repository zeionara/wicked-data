import XCTest
import PcgRandom
import Logging
@testable import wickedData

final class wickedDataTests: XCTestCase {
    func testExample() throws {
        var logger = Logger(label: "test")
        logger.logLevel = .info

        let adapter = BlazegraphAdapter()
        let query = """
        SELECT (count(?h) as ?count) WHERE 
        {
            ?h ?r ?t
        }
        """

        BlockingTask {
            let sample = try! await adapter.sample(CountingQuery(text: query))
            print(sample.count)
        }
        
        // let adapter = WikiDataAdapter()
        // XCTAssertEqual(adapter.url, "http://query.wikidata.org:80")
        // let query = """
        // SELECT DISTINCT ?foo ?bar WHERE 
        // {
        //   ?foo wdt:P2152 ?bar.
        //   SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        // }
        // LIMIT 2
        // """

        // let queryWithLabels = """
        // SELECT DISTINCT ?foo ?fooLabel ?bar ?barLabel WHERE 
        // {
        //   ?foo wdt:P2152 ?bar.
        //   filter (?foo != ?bar).
        //   SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        // }
        // LIMIT 7
        // """

        // BlockingTask {
        //     let sample = try! await adapter.sample(DemoQuery(text: query))
        //     XCTAssertEqual(sample.results.bindings.count, 2)

        //     let sampleWithLabels = try! await adapter.sample(DemoQuery(text: queryWithLabels))
        //     XCTAssertEqual(sampleWithLabels.results.bindings.count, 7)

        //     _ = sampleWithLabels.results.bindings.map{ binding in
        //         logger.info("\(binding.fooLabel?.value ?? " - ") is the antiparticle of \(binding.barLabel?.value ?? " - ")")
        //     }

        //     for triple in sampleWithLabels.triples {
        //         logger.trace("\(triple)")
        //     }

        //     logger.trace("\(sampleWithLabels.compressed)")

        //     sampleWithLabels.cv(seed: 17) { subset in
        //         logger.trace("\(subset)")
        //     }
        // }
        // sampleWithLabels.cv(seed: 17) { subset in
        //         logger.info("\(subset)")
        //     }
        // }
    }
}
