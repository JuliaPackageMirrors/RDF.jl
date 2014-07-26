using RDF

using Base.Test
using URIParser

@test Graph(URI("http://graphuri.test")).name == URI("http://graphuri.test")
@test_throws Graph("http://not.an.URI.but.a.string")

g = Graph(URI("http://example.org"))
push!(g, URI("http://test.org/1"), URI("http://test.org/2"), URI("http://test.org/1"))
push!(g, URI("http://test.org/1"), URI("http://test.org/3"), 3.141)
push!(g, URI("http://test.org/1"), URI("http://test.org/4"), URI("http://test.org/1"))
push!(g, URI("http://test.org/1"), URI("http://test.org/4"), 123)
push!(g, URI("http://test.org/2"), URI("http://test.org/2"), URI("http://test.org/1"))
push!(g, URI("http://test.org/2"), URI("http://test.org/2"), "Hullo!")

@test g.size == 6

s = IOBuffer()
ntriples(g, s)
@test length(split(takebuf_string(s), "\n")) == 7

s = IOBuffer()
nquads(g, s)
@test length(split(takebuf_string(s), "\n")) == 7

s = IOBuffer()
turtle(g, s)
@test length(split(takebuf_string(s), "\n")) == 7

@test pop!(g, URI("http://test.org/2")) == 2
@test g.size == 4
@test pop!(g, URI("http://test.org/1"), URI("http://test.org/4")) == 2
@test g.size == 2

