abstract type TulipaBuilderError <: Exception end

struct ExistingKeyError <: TulipaBuilderError
    msg::Any
end
