# wicked-data

A project containing implementation of adapters for popular open-access knowledge databases which allows to sample data with certain properties from these collections. Such samples can be applied for testing semantic data models, particularly compare different approaches for knowledge graph embeddings using implementations provided by other developers.

Currently the main goal is to allow for simple data fetching from wiki-data source and convert the graphs into formats supported by external tools.

# Usage

Include into your global `dependencies` section in the `Package.swift` the following statement: 

```sh
.package(url: "https://github.com/zeionara/wicked-data.git", .branch("master"))
```

Then for making it available in the source code of your modules you need to append the respective call for every desired product declaration as well:

```sh
.product(name: "wickedData", package: "wickedData")
```

After these prerequisites are met, the library can be imported and it's components will become available:

```swift
import wickedData

let adapter = WikiDataAdapter(address: "query.wikidata.org", port: 80)

let query = """
SELECT DISTINCT ?foo ?fooLabel ?bar ?barLabel WHERE 
{
  ?foo wdt:P2152 ?bar.
  filter (?foo != ?bar).
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
}
LIMIT 7
"""

let sample = try! await adapter.sample(DemoQuery(text: query))

_ = sample.results.bindings.map{ binding in
    print("\(binding.fooLabel?.value ?? " - ") is the antiparticle of \(binding.barLabel?.value ?? " - ")")
}
```

Example of output:

```swift
antimatter composed of antiquarks is the antiparticle of matter composed of quarks
deuterium is the antiparticle of antideuterium
bottom antiquark is the antiparticle of bottom quark
bottom quark is the antiparticle of bottom antiquark
nucleon is the antiparticle of antinucleon
antileptonic antimatter is the antiparticle of leptonic matter
negative rho meson is the antiparticle of positive rho meson
```

# Testing

For testing that everything works well, use the standard call:

```
swift test
```

