Julia RDF Package
=================

[![Build Status](https://travis-ci.org/joejimbo/RDF.jl.svg?branch=master)](https://travis-ci.org/joejimbo/RDF.jl)
[![Coverage Status](https://coveralls.io/repos/joejimbo/RDF.jl/badge.png?branch=master)](https://coveralls.io/r/joejimbo/RDF.jl?branch=master)

RDF package for working with RDF Graphs in [Julia](http://julialang.org/). Supports serialization as [RDF N-Triples](http://www.w3.org/TR/n-triples/), [RDF N-Quads](http://www.w3.org/TR/n-quads/) and [Turtle](http://www.w3.org/TR/turtle/).

### Installation

In the Julia command line, type:

    Pkg.add("RDF")

Later, to pull in updates (newer versions of `RDF.jl`):

    Pkg.update()

### Examples

Create a graph, add some statements (triples), output them as Turtle:

    using RDF
    using URIParser
   
    g = Graph(URI("http://myresource.org/example"))
    
    push!(g, URI("http://myresource.org/example/1"), URI("http://myresource.org/ont/related"), URI("http://myresource.org/example/2"))
    push!(g, URI("http://myresource.org/example/1"), URI("http://myresource.org/ont/related"), URI("http://myresource.org/example/3"))
    push!(g, URI("http://myresource.org/example/1"), URI("http://www.w3.org/2000/01/rdf-schema#label"), "Label #1")
    push!(g, URI("http://myresource.org/example/2"), URI("http://myresource.org/ont/related"), URI("http://myresource.org/example/3"))
    push!(g, URI("http://myresource.org/example/2"), URI("http://www.w3.org/2000/01/rdf-schema#label"), "Label #2")
    push!(g, URI("http://myresource.org/example/3"), URI("http://www.w3.org/2000/01/rdf-schema#label"), "Label #3")
    
    turtle(g, STDOUT)

The output will look like this:

    <http://myresource.org/example/2> <http://myresource.org/ont/related> <http://myresource.org/example/3> ;
        <http://www.w3.org/2000/01/rdf-schema#label> "Label #2" .
    <http://myresource.org/example/1> <http://myresource.org/ont/related> <http://myresource.org/example/2> ,
            <http://myresource.org/example/3> ;
        <http://www.w3.org/2000/01/rdf-schema#label> "Label #1" .
    <http://myresource.org/example/3> <http://www.w3.org/2000/01/rdf-schema#label> "Label #3" .

Changing the output to RDF N-Triples or RDF N-Quads:

    ntriples(g, STDOUT)
    nquads(g, STDOUT)

`STDOUT` can be changed to file streams or instances of `IOBuffer` or `PipeBuffer`.

### Feature Requests & To-do

See [issues](https://github.com/joejimbo/RDF.jl/issues).

### License

See [LICENSE.md](https://github.com/joejimbo/RDF.jl/blob/master/LICENSE.md).
