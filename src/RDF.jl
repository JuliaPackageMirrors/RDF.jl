module RDF

using URIParser

export
    # types
    Graph,
    # functions (graph manipulation)
    push!,
    pop!,
    # functions (graph serialization)
    ntriples,
    nquads,
    turtle

type Graph
    name::URI
    size::Int64
    statements::Dict{String,Dict{String,Set{Union(Number,String,URI)}}}

    Graph(name::URI) = new(name, 0, Dict{String,Dict{String,Set{Union(Number,String,URI)}}}())
end

function push!(graph::Graph,
               subject::URI,
               predicate::URI,
               object::Union(Number,String,URI))
    # Get dict mappings:
    subject_dict = get(graph.statements, string(subject), Dict{String,Set{Union(Number,String,URI)}}())
    predicate_set = get(subject_dict, string(predicate), Set{Union(Number,String,URI)}())

    # Add statement:
    objects_num = length(predicate_set)
    Base.push!(predicate_set, object)
    if objects_num != length(predicate_set)
        graph.size += 1
    end

    # Store newly created dicts/sets:
    if !haskey(subject_dict, object)
        subject_dict[string(predicate)] = predicate_set
    end
    if !haskey(graph.statements, subject)
        graph.statements[string(subject)] = subject_dict
    end
end

function pop!(graph::Graph,
              subject::URI)
    # Get dict mappings;
    if !haskey(graph.statements, string(subject))
        return 0
    end
    subject_dict = Base.pop!(graph.statements, string(subject))

    # Remove statements:
    removed_statements = 0
    for predicate_objects = subject_dict
        removed_statements += length(predicate_objects[2])
    end
    graph.size -= removed_statements

    # Final number of removed statements:
    return removed_statements
end

function pop!(graph::Graph,
              subject::URI,
              predicate::URI)
    # Get dict mappings:
    if !haskey(graph.statements, string(subject))
        return 0
    end
    subject_dict = graph.statements[string(subject)]
    if !haskey(subject_dict, string(predicate))
        return 0
    end

    # Remove statements:
    objects = Base.pop!(subject_dict, string(predicate))
    removed_statements = length(objects)
    graph.size -= removed_statements

    # Remove empty dict:
    if length(subject_dict) == 0
        Base.pop!(graph.statements, string(subject))
    end

    # Final number of removed statements:
    return removed_statements
end

function pop!(graph::Graph,
              subject::URI,
              predicate::URI,
              object::Union(Number,String,URI))
    # Get dict mappings:
    if !haskey(graph.statements, string(subject))
        return 0
    end
    subject_dict = get(graph.statements, string(subject))
    if !haskey(subject_dict, string(predicate))
        return 0
    end
    predicate_set = get(subject_dict, string(predicate))

    # Remove statement:
    Base.pop!(predicate_set, object)
    graph.size -= 1

    # Remove empty dicts/sets:
    if length(predicate_set) == 0
        Base.pop!(subject_dict, string(predicate))
    end
    if length(subject_dict) == 0
        Base.pop!(graph.statements, string(subject))
    end

    # Final number of removed statements:
    return 1
end

function ntriples(graph::Graph,
                  out::Any)
    for statement = graph.statements
        for predicate_object = statement[2]
            for object = predicate_object[2]
                write(out, join(triple(statement[1], predicate_object[1], object)), " .\n")
            end
        end
    end
end

function nquads(graph::Graph,
                out::Any)
    for statement = graph.statements
        for predicate_object = statement[2]
            for object = predicate_object[2]
                write(out, join(triple(statement[1], predicate_object[1], object)), " <", string(graph.name), "> .\n")
            end
        end
    end
end

function turtle(graph::Graph,
                out::Any)
    subject_same = false
    predicate_same = false
    last_subject = nothing
    last_predicate = nothing
    last_object = nothing
    for statement = graph.statements
        for predicate_object = statement[2]
            for object = predicate_object[2]
                # Statement:
                subject = statement[1]
                predicate = predicate_object[1]

                # Serialize:
                prefix = ""
                if subject_same
                    prefix *= "    "
                elseif last_subject != nothing
                    prefix *= uri_rdf(last_subject) * " "
                end
                if predicate_same
                    prefix *= "    "
                elseif last_predicate != nothing
                    prefix *= uri_rdf(last_predicate) * " "
                end
                subject_same = last_subject == subject
                predicate_same = subject_same & (last_predicate == predicate)
                if subject_same
                    if predicate_same
                        write(out, prefix, object_rdf(last_object), " ,\n")
                    else
                        write(out, prefix, object_rdf(last_object), " ;\n")
                    end
                elseif last_subject != nothing
                    write(out, prefix, object_rdf(last_object), " .\n")
                end

                # Remember this statement, which only determined `separator`, but has not been serialized yet:
                last_subject = subject
                last_predicate = predicate
                last_object = object
            end
        end
    end

    # Serialize saved statement, if exists:
    if last_subject != nothing
        if subject_same
            if predicate_same
                write(out, "        ", object_rdf(last_object), " .\n")
            else
                write(out, "    ", uri_rdf(last_predicate), " ", object_rdf(last_object), " .\n")
            end
        else
            write(out, join(triple(last_subject, last_predicate, last_object)), " .\n")
        end
    end
end

function triple(subject::String,
                predicate::String,
                object::Union(String,Number,URI))
    return uri_rdf(subject), " ", uri_rdf(predicate), " ", object_rdf(object)
end

function uri_rdf(uri::String)
    # TODO Not complete yet; needs to handle URI encoding/escaping.
    return string("<", uri, ">")
end

function object_rdf(value::String)
    # TODO I wonder whether there is a simpler way to do this...
    # TODO Also, this function is not complete yet.
    previous = nothing
    escaped_string = utf8("")
    for character = value
        if previous == nothing && character == '"'
            escaped_string *= "\\\""
        elseif character == '"' && previous != '"'
            escaped_string *= "\\\""
        else
            escaped_string *= string(character)
        end
        previous = character
    end
    return "\"" * escaped_string * "\""
end

function object_rdf(value::Number)
    # TODO Add RDF/RDFS type based on the particular number we're seeing.
    return string(value)
end

function object_rdf(value::URI)
    return uri_rdf(string(value))
end

end # module RDF

