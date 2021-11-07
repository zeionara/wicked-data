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

        let graph = """
        @prefix ren: <https://relentness.nara.zeio/Demo/0000/> .

        ren:Q82586 ren:antiparticleOf ren:Q1066748 .
        ren:Q3229 ren:antiparticleOf ren:Q2225 .
        ren:Q17255429 ren:antiparticleOf ren:Q28855263 .
        ren:Q28739684 ren:antiparticleOf ren:Q28729648 .
        ren:Q6778 ren:antiparticleOf ren:Q3151 .
        ren:Q17255430 ren:antiparticleOf ren:Q306600 .
        ren:Q18481607 ren:antiparticleOf ren:Q6732 .
        ren:Q3151 ren:antiparticleOf ren:Q6778 .
        ren:Q306600 ren:antiparticleOf ren:Q17255430 .
        ren:Q6754 ren:antiparticleOf ren:Q11905754 .
        ren:Q28855250 ren:antiparticleOf ren:Q102165 .
        ren:Q6745 ren:antiparticleOf ren:Q18481576 .
        ren:Q23894016 ren:antiparticleOf ren:Q619699 .
        ren:Q279735 ren:antiparticleOf ren:Q2147400 .
        ren:Q619699 ren:antiparticleOf ren:Q23894016 .
        ren:Q1066748 ren:antiparticleOf ren:Q82586 .
        ren:Q2294 ren:antiparticleOf ren:Q6763 .
        ren:Q28729648 ren:antiparticleOf ren:Q28739684 .
        ren:Q18481576 ren:antiparticleOf ren:Q6745 .
        ren:Q6718 ren:antiparticleOf ren:Q2052084 .
        ren:Q2052084 ren:antiparticleOf ren:Q6718 .
        ren:Q102296 ren:antiparticleOf ren:Q107575 .
        ren:Q156530 ren:antiparticleOf ren:Q2348 .
        ren:Q28736576 ren:antiparticleOf ren:Q28728519 .
        ren:Q2172777 ren:antiparticleOf ren:Q188392 .
        ren:Q107575 ren:antiparticleOf ren:Q102296 .
        ren:Q6786 ren:antiparticleOf ren:Q2174695 .
        ren:Q188392 ren:antiparticleOf ren:Q2172777 .
        ren:Q11905736 ren:antiparticleOf ren:Q2259051 .
        ren:Q14861565 ren:antiparticleOf ren:Q159731 .
        ren:Q4044799 ren:antiparticleOf ren:Q11905755 .
        ren:Q60063013 ren:antiparticleOf ren:Q60062950 .
        ren:Q28921572 ren:antiparticleOf ren:Q83197 .
        ren:Q28728519 ren:antiparticleOf ren:Q28736576 .
        ren:Q2126 ren:antiparticleOf ren:Q11905758 .
        ren:Q28729554 ren:antiparticleOf ren:Q28736567 .
        ren:Q2259051 ren:antiparticleOf ren:Q11905736 .
        ren:Q159731 ren:antiparticleOf ren:Q14861565 .
        ren:Q11905753 ren:antiparticleOf ren:Q9617716 .
        ren:Q6732 ren:antiparticleOf ren:Q18481607 .
        ren:Q11905755 ren:antiparticleOf ren:Q4044799 .
        ren:Q2348 ren:antiparticleOf ren:Q156530 .
        ren:Q102165 ren:antiparticleOf ren:Q28855250 .
        ren:Q11905754 ren:antiparticleOf ren:Q6754 .
        ren:Q556 ren:antiparticleOf ren:Q216121 .
        ren:Q9617716 ren:antiparticleOf ren:Q11905753 .
        ren:Q83197 ren:antiparticleOf ren:Q28921572 .
        ren:Q2225 ren:antiparticleOf ren:Q3229 .
        ren:Q6763 ren:antiparticleOf ren:Q2294 .
        ren:Q17254249 ren:antiparticleOf ren:Q17254273 .
        ren:Q28855263 ren:antiparticleOf ren:Q17255429 .
        ren:Q2174695 ren:antiparticleOf ren:Q6786 .
        ren:Q60062950 ren:antiparticleOf ren:Q60063013 .
        ren:Q17254273 ren:antiparticleOf ren:Q17254249 .
        ren:Q28736567 ren:antiparticleOf ren:Q28729554 .
        ren:Q2147400 ren:antiparticleOf ren:Q279735 .
        ren:Q216121 ren:antiparticleOf ren:Q556 .
        ren:Q11905758 ren:antiparticleOf ren:Q2126 .
        """
        
        let queryWithAggregation = """
        select (count(?h) as ?count) (?r as ?relation) where {
          ?h ?r ?t.
          ?t ?r ?h.
          filter(str(?h) > str(?t))
        }
        group by ?r
        """

        BlockingTask {
            print("Testing...")
            let sample = try! await adapter.sample(CountingQuery(text: query))
            print("Currently there are \(sample.count) triples in theknowledge base")

            // let response = try! await adapter.update(UpdateQuery(text: graph))
            // print("Inserted \(response.nModifiedTriples) in \(response.executionTimeInMilliseconds) ms")

            let sampleWithAggregation = try! await adapter.sample(CountingQueryWithAggregation<CountableBindingTypeWithOneRelationAggregation>(text: queryWithAggregation))
            for triple in sampleWithAggregation.triples {
                print(triple)
            }
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
