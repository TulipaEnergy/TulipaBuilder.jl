
mutable struct TulipaFlow
    from::Symbol
    to::Symbol

    basic_data::Dict{Symbol,Any}
    commission_year_data::PerYear{Dict{Symbol,Any}}
    milestone_year_data::PerYear{Dict{Symbol,Any}}
    both_years_data::PerYears{Dict{Symbol,Any}}

    function TulipaFlow(from::Symbol, to::Symbol; kwargs...)
        return new(
            from,
            to,
            Dict{Symbol,Any}(kwargs...),
            PerYear{Dict{Symbol,Any}}(),
            PerYear{Dict{Symbol,Any}}(),
            PerYears{Dict{Symbol,Any}}(),
        )
    end
end

function attach_commission_data!(flow::TulipaFlow, year; kwargs...)
    flow.commission_year_data[year] = Dict{Symbol,Any}(kwargs...)
end

function attach_milestone_data!(flow::TulipaFlow, year; kwargs...)
    flow.milestone_year_data[year] = Dict{Symbol,Any}(kwargs...)
end

function attach_both_years_data!(
    flow::TulipaFlow,
    commission_year,
    milestone_year;
    kwargs...,
)
    @assert milestone_year ≥ commission_year
    flow.both_years_data[(commission_year, milestone_year)] = Dict{Symbol,Any}(kwargs...)
end

