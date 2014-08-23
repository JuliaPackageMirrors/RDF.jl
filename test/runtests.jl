using RDF

using Base.Test
using URIParser

@test Graph(URI("http://graphuri.test")).name == URI("http://graphuri.test")
@test_throws MethodError Graph("http://not.an.URI.but.a.string")

# On run...
#   1 -- insert literals using Julia native types
#   2 -- insert literals via Literal instances, but without annotations
#   3 -- insert literals via Literal instances; 1 parameter
#   4 -- insert literals via Literal instances; 2 parameters
for run in range(1, 4)
    g = Graph(URI("http://example.org"))
    push!(g, URI("http://test.org/1"), URI("http://test.org/2"), URI("http://test.org/1"))
    push!(g, URI("http://test.org/1"), URI("http://test.org/4"), URI("http://test.org/1"))
    push!(g, URI("http://test.org/2"), URI("http://test.org/2"), URI("http://test.org/1"))

    if run == 1
        push!(g, URI("http://test.org/1"), URI("http://test.org/3"), 3.141)
        push!(g, URI("http://test.org/1"), URI("http://test.org/4"), 123)
        push!(g, URI("http://test.org/2"), URI("http://test.org/2"), "Hullo!")
    elseif run == 2
        push!(g, URI("http://test.org/1"), URI("http://test.org/3"), Literal(3.141))
        push!(g, URI("http://test.org/1"), URI("http://test.org/4"), Literal(123))
        push!(g, URI("http://test.org/2"), URI("http://test.org/2"), Literal("Hullo!"))
    elseif run == 3
        push!(g, URI("http://test.org/1"), URI("http://test.org/3"), Literal(3.141, URI("http://www.w3.org/2001/XMLSchema#float")))
        push!(g, URI("http://test.org/1"), URI("http://test.org/4"), Literal(123, URI("http://www.w3.org/2001/XMLSchema#integer")))
        push!(g, URI("http://test.org/2"), URI("http://test.org/2"), Literal("Hullo!", "en"))
    elseif run == 4
        push!(g, URI("http://test.org/1"), URI("http://test.org/3"), Literal(3.141, URI("http://www.w3.org/2001/XMLSchema#float"), nothing))
        push!(g, URI("http://test.org/1"), URI("http://test.org/4"), Literal(123, URI("http://www.w3.org/2001/XMLSchema#integer"), nothing))
        push!(g, URI("http://test.org/2"), URI("http://test.org/2"), Literal("Hullo!", nothing, "en"))
    end

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
end

# W3C Turtle Examples

w3c_examples = [
    (7, """@base <http://example.org/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix rel: <http://www.perceive.net/schemas/relationship/> .

<#green-goblin>
    rel:enemyOf <#spiderman> ;
    a foaf:Person ;    # in the context of the Marvel universe
    foaf:name "Green Goblin" .

<#spiderman>
    rel:enemyOf <#green-goblin> ;
    a foaf:Person ;
    foaf:name "Spiderman", "Человек-паук"@ru ."""),
    (1, """<http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green-goblin> ."""),
    (2, """<http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green-goblin> ;
				<http://xmlns.com/foaf/0.1/name> "Spiderman" ."""),
    (2, """<http://example.org/#spiderman> <http://www.perceive.net/schemas/relationship/enemyOf> <http://example.org/#green-goblin> .
<http://example.org/#spiderman> <http://xmlns.com/foaf/0.1/name> "Spiderman" ."""),
    (2, """<http://example.org/#spiderman> <http://xmlns.com/foaf/0.1/name> "Spiderman", "Человек-паук"@ru ."""),
    (2, """<http://example.org/#spiderman> <http://xmlns.com/foaf/0.1/name> "Spiderman" .
<http://example.org/#spiderman> <http://xmlns.com/foaf/0.1/name> "Человек-паук"@ru ."""),
    (1, """@prefix somePrefix: <http://www.perceive.net/schemas/relationship/> .

<http://example.org/#green-goblin> somePrefix:enemyOf <http://example.org/#spiderman> ."""),
    (1, """PREFIX somePrefix: <http://www.perceive.net/schemas/relationship/>

<http://example.org/#green-goblin> somePrefix:enemyOf <http://example.org/#spiderman> ."""),
    (9, """# A triple with all absolute IRIs
<http://one.example/subject1> <http://one.example/predicate1> <http://one.example/object1> .

@base <http://one.example/> .
<subject2> <predicate2> <object2> .     # relative IRIs, e.g. http://one.example/subject2

BASE <http://one.example/>
<subject2> <predicate2> <object2> .     # relative IRIs, e.g. http://one.example/subject2

@prefix p: <http://two.example/> .
p:subject3 p:predicate3 p:object3 .     # prefixed name, e.g. http://two.example/subject3

PREFIX p: <http://two.example/>
p:subject3 p:predicate3 p:object3 .     # prefixed name, e.g. http://two.example/subject3

@prefix p: <path/> .                    # prefix p: now stands for http://one.example/path/
p:subject4 p:predicate4 p:object4 .     # prefixed name, e.g. http://one.example/path/subject4

@prefix : <http://another.example/> .    # empty prefix
:subject5 :predicate5 :object5 .        # prefixed name, e.g. http://another.example/subject5

:subject6 a :subject7 .                 # same as :subject6 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> :subject7 .

<http://伝言.example/?user=أكرم&amp;channel=R%26D> a :subject8 . # a multi-script subject IRI ."""),
    (2, """@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://example.org/#green-goblin> foaf:name "Green Goblin" .

<http://example.org/#spiderman> foaf:name "Spiderman" ."""),
    (7, """@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix show: <http://example.org/vocab/show/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

show:218 rdfs:label "That Seventies Show"^^xsd:string .            # literal with XML Schema string datatype
show:218 rdfs:label "That Seventies Show"^^<http://www.w3.org/2001/XMLSchema#string> . # same as above
show:218 rdfs:label "That Seventies Show" .                                            # same again
show:218 show:localName "That Seventies Show"@en .                 # literal with a language tag
show:218 show:localName 'Cette Série des Années Soixante-dix'@fr . # literal delimited by single quote
show:218 show:localName "Cette Série des Années Septante"@fr-be .  # literal with a region subtag
show:218 show:blurb '''This is a multi-line                        # literal with embedded new lines and quotes
literal with many quotes (\"\"\"\"\")
and up to two sequential apostrophes ('').''' ."""),
    (3, """@prefix : <http://example.org/elements> .                                                                              
<http://en.wikipedia.org/wiki/Helium>                                                                                  
    :atomicNumber 2 ;               # xsd:integer                                                                      
    :atomicMass 4.002602 ;          # xsd:decimal                                                                      
    :specificGravity 1.663E-4 .     # xsd:double"""),
    (1, """@prefix : <http://example.org/stats> .
<http://somecountry.example/census2007>
    :isLandlocked false .           # xsd:boolean"""),
    (2, """@prefix foaf: <http://xmlns.com/foaf/0.1/> .

_:alice foaf:knows _:bob .
_:bob foaf:knows _:alice ."""),
    (2, """@prefix foaf: <http://xmlns.com/foaf/0.1/> .

# Someone knows someone else, who has the name "Bob".
[] foaf:knows [ foaf:name "Bob" ] ."""),
    (6, """@prefix foaf: <http://xmlns.com/foaf/0.1/> .

[ foaf:name "Alice" ] foaf:knows [
    foaf:name "Bob" ;
    foaf:knows [
        foaf:name "Eve" ] ;
    foaf:mbox <bob@example.com> ] ."""),
    (6, """_:a <http://xmlns.com/foaf/0.1/name> "Alice" .
_:a <http://xmlns.com/foaf/0.1/knows> _:b .
_:b <http://xmlns.com/foaf/0.1/name> "Bob" .
_:b <http://xmlns.com/foaf/0.1/knows> _:c .
_:c <http://xmlns.com/foaf/0.1/name> "Eve" .
_:b <http://xmlns.com/foaf/0.1/mbox> <bob@example.com> ."""),
    (6, """@prefix : <http://example.org/foo> .
# the object of this triple is the RDF collection blank node
:subject :predicate ( :a :b :c ) .

# an empty collection value - rdf:nil
:subject :predicate2 () ."""),
    (4, """@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .
@prefix ex: <http://example.org/stuff/1.0/> .

<http://www.w3.org/TR/rdf-syntax-grammar>
  dc:title "RDF/XML Syntax Specification (Revised)" ;
  ex:editor [
    ex:fullname "Dave Beckett";
    ex:homePage <http://purl.org/net/dajobe/>
  ] ."""),
    (3, """PREFIX : <http://example.org/stuff/1.0/>
:a :b ( "apple" "banana" ) ."""),
    (7, """@prefix : <http://example.org/stuff/1.0/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
:a :b
  [ rdf:first "apple";
    rdf:rest [ rdf:first "banana";
               rdf:rest rdf:nil ]
  ] ."""),
    (2, """@prefix : <http://example.org/stuff/1.0/> .

:a :b "The first line\nThe second line\n  more" .

:a :b \"\"\"The first line
The second line
  more\"\"\" ."""),
    (5, """@prefix : <http://example.org/stuff/1.0/> .
(1 2.0 3E1) :p "w" ."""),
    (7, """@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    _:b0  rdf:first  1 ;
          rdf:rest   _:b1 .
    _:b1  rdf:first  2.0 ;
          rdf:rest   _:b2 .
    _:b2  rdf:first  3E1 ;
          rdf:rest   rdf:nil .
    _:b0  :p         "w" ."""),
    (9, """PREFIX : <http://example.org/stuff/1.0/>
(1 [:p :q] ( 2 ) ) :p2 :q2 ."""),
    (9, """@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    _:b0  rdf:first  1 ;
          rdf:rest   _:b1 .
    _:b1  rdf:first  _:b2 .
    _:b2  :p         :q .
    _:b1  rdf:rest   _:b3 .
    _:b3  rdf:first  _:b4 .
    _:b4  rdf:first  2 ;
          rdf:rest   rdf:nil .
    _:b3  rdf:rest   rdf:nil .""")
]

for n in range(1, length(w3c_examples))
    println("W3C Turtle Example " * string(n))
    example = w3c_examples[n]
    num_triples, turtle = example
    println(turtle)
    g = Graph(URI("http://example.org"))
    load_turtle!(g, IOBuffer(turtle))

    @test g.size == num_triples
end

