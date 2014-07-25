module RDF

using URIParser

export
    # types
    Graph,
    Statement,
    # functions & macros
    add!

type Graph
    name::URI
    statements::Dict{URI,Dict{URI,Set{Union(Number,String,URI)}}}

    Graph(name::URI) = new(name, Dict{URI,Dict{URI,Set{Union(Number,String,URI)}}}())
end

type Statement
    subject::URI
    predicate::URI
    object::Union(Number,String,URI)
end

function add!(graph::Graph,
              subject::URI,
              predicate::URI,
              object::Union(Number,String,URI))
    # Get dict mappings:
    subject_dict = get(graph.statements, subject, Dict{URI,Set{Union(Number,String,URI)}}())
    predicate_set = get(subject_dict, predicate, Set{Union(Number,String,URI)}())

    # Add statement:
    push!(predicate_set, object)

    # Store newly created dicts/sets:
    if !haskey(subject_dict, object)
        subject_dict[predicate] = predicate_set
    end
    if !haskey(graph.statements, subject)
        graph.statements[subject] = subject_dict
    end
end

function add!(graph::Graph,
              statement::Statement)
    add!(graph, statement.subject, statement.predicate, statement.object)
end

function ntriples(graph::Graph)
    
end

end # module RDF

# Tests...
using RDF

g = RDF.Graph(URIParser.URI("http://example.org"))
add!(g, URIParser.URI("http://test.org/1"), URIParser.URI("http://test.org/2"), URIParser.URI("http://test.org/1"))

