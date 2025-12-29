abstract type TulipaBuilderError <: Exception end

"""
    ExistingKeyError(msg)

Error indicating that a key is already present. The `msg` should help specify
which key and where.
"""
struct ExistingKeyError <: TulipaBuilderError
    msg::Any
end
