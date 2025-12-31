"""
Internal structure to hold all information of a given Flow.
It's used internally inside the graph that's inside the TulipaData object.
"""
mutable struct TulipaFlow{KeyType}
    from::KeyType
    to::KeyType

    basic_data::Dict{Symbol,Any}
    commission_year_data::PerYear{Dict{Symbol,Any}}
    milestone_year_data::PerYear{Dict{Symbol,Any}}
    both_years_data::PerYears{Dict{Symbol,Any}}

    """
        struct TulipaFlow(from_asset_name, to_asset_name)

    Create a new `TulipaFlow` for the flow between assets named
    `from_asset_name` and `to_asset_name`, with data provided by the keyword
    arguments.
    """
    function TulipaFlow(from::KeyType, to::KeyType; kwargs...) where {KeyType}
        return new{KeyType}(
            from,
            to,
            Dict{Symbol,Any}(kwargs...),
            PerYear{Dict{Symbol,Any}}(),
            PerYear{Dict{Symbol,Any}}(),
            PerYears{Dict{Symbol,Any}}(),
        )
    end
end

# TODO: Add on_conflict keyword

"""
    attach_commission_data!(flow::TulipaFlow, year; kwargs...)

Internal version of `attach_commission_data!` acting directly on a `TulipaFlow`
object.
"""
function attach_commission_data!(flow::TulipaFlow, year; kwargs...)
    flow.commission_year_data[year] = Dict{Symbol,Any}(kwargs...)
    return flow
end

"""
    attach_milestone_data!(flow::TulipaFlow, year; kwargs...)

Internal version of `attach_milestone_data!` acting directly on a `TulipaFlow`
object.
"""
function attach_milestone_data!(flow::TulipaFlow, year; kwargs...)
    flow.milestone_year_data[year] = Dict{Symbol,Any}(kwargs...)
    return flow
end

"""
    attach_both_years_data!(flow::TulipaFlow, commission_year, milestone_year; kwargs...)

Internal version of `attach_both_years_data!` acting directly on a `TulipaFlow`
object.
"""
function attach_both_years_data!(
    flow::TulipaFlow,
    commission_year,
    milestone_year;
    kwargs...,
)
    @assert milestone_year ≥ commission_year
    flow.both_years_data[(commission_year, milestone_year)] = Dict{Symbol,Any}(kwargs...)
    return flow
end
