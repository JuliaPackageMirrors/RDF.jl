using RDF

using Base.Test
using URIParser

@test Graph(URI("http://graphuri.test")).name == URI("http://graphuri.test")
@test_throws Graph("http://not.an.URI.but.a.string")

