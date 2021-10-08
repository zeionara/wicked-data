import XCTest
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

        BlockingTask {
            let sample = try! await adapter.sample(DemoQuery(text: query))
            XCTAssertEqual(sample.results.bindings.count, 2)
        }
    }
}
