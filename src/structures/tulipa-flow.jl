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

    profiles::Dict{Tuple{ProfileType,Int,Int,ScenarioType},Vector{Float64}}

    partitions::Dict{Tuple{Int,Int},Dict{Symbol,Any}}

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
            Dict(),
            Dict(),
        )
    end
end

# TODO: Add on_conflict keyword

"""
    attach_commission_data!(flow::TulipaFlow, year; on_conflict=:overwrite, kwargs...)

Internal version of `attach_commission_data!` acting directly on a `TulipaFlow`
object.
"""
function attach_commission_data!(
    flow::TulipaFlow,
    year;
    on_conflict = :overwrite,
    kwargs...,
)
    # If the year has not been set, then it is not possible to have conflicts
    if !haskey(flow.commission_year_data, year)
        flow.commission_year_data[year] = Dict{Symbol,Any}(kwargs...)
        return flow
    end
    for (k, v) in kwargs
        if !haskey(flow.commission_year_data[year], k) || on_conflict == :overwrite
            # If the key doesn't exist or can be overwritten
            flow.commission_year_data[year][k] = v
        elseif on_conflict == :error
            # The key exists and can't be overwritten
            throw(
                ExistingKeyError(
                    "Key $k has already been attached for flow=($(flow.from),$(flow.to)), commission_year=$year",
                ),
            )
        end # on_conflict = :skip, The key exists so the new value is ignored
    end
    return flow
end

"""
    attach_milestone_data!(flow::TulipaFlow, year; on_conflict=:overwrite, kwargs...)

Internal version of `attach_milestone_data!` acting directly on a `TulipaFlow`
object.
"""
function attach_milestone_data!(flow::TulipaFlow, year; on_conflict = :overwrite, kwargs...)
    # If the year has not been set, then it is not possible to have conflicts
    if !haskey(flow.milestone_year_data, year)
        flow.milestone_year_data[year] = Dict{Symbol,Any}(kwargs...)
        return flow
    end
    for (k, v) in kwargs
        if !haskey(flow.milestone_year_data[year], k) || on_conflict == :overwrite
            # If the key doesn't exist or can be overwritten
            flow.milestone_year_data[year][k] = v
        elseif on_conflict == :error
            # The key exists and can't be overwritten
            throw(
                ExistingKeyError(
                    "Key $k has already been attached for flow=($(flow.from),$(flow.to)), milestone_year=$year",
                ),
            )
        end # on_conflict = :skip, The key exists so the new value is ignored
    end
    return flow
end

"""
    attach_both_years_data!(flow::TulipaFlow, commission_year, milestone_year; on_conflict=:overwrite, kwargs...)

Internal version of `attach_both_years_data!` acting directly on a `TulipaFlow`
object.
"""
function attach_both_years_data!(
    flow::TulipaFlow,
    commission_year,
    milestone_year;
    on_conflict = :overwrite,
    kwargs...,
)
    if !(on_conflict in (:error, :overwrite, :skip))
        throw(
            ArgumentError(
                "`on_conflict` must be one of `:error`, `:overwrite`, or `:skip`",
            ),
        )
    end
    @assert milestone_year ≥ commission_year
    year_key = (commission_year, milestone_year)
    # If the year has not been set, then it is not possible to have conflicts
    if !haskey(flow.both_years_data, year_key)
        flow.both_years_data[year_key] = Dict{Symbol,Any}(kwargs...)
        return flow
    end
    for (k, v) in kwargs
        if !haskey(flow.both_years_data[year_key], k) || on_conflict == :overwrite
            # If the key doesn't exist or can be overwritten
            flow.both_years_data[year_key][k] = v
        elseif on_conflict == :error
            # The key exists and can't be overwritten
            throw(
                ExistingKeyError(
                    "Key $k has already been attached for flow=($(flow.from),$(flow.to)), milestone_year=$milestone_year, commission_year=$commission_year",
                ),
            )
        end # on_conflict = :skip, The key exists so the new value is ignored
    end
    return flow
end

"""
    attach_profile!(flow::TulipaFlow, profile_type, milestone_year, profile_value; commission_year=milestone_year, scenario=DEFAULT_SCENARIO)

Internal version of `attach_profile!` acting directly on a `TulipaFlow` object.
The `commission_year` defaults to `milestone_year` when not specified.
"""
function attach_profile!(
    flow::TulipaFlow,
    profile_type::ProfileType,
    milestone_year::Int,
    profile_value::Vector;
    commission_year::Int = milestone_year,
    scenario::Int = DEFAULT_SCENARIO,
)
    key = (profile_type, milestone_year, commission_year, scenario)
    if haskey(flow.profiles, key)
        throw(
            ExistingKeyError(
                "Profile of type '$profile_type' for milestone_year '$milestone_year', commission_year '$commission_year' and scenario '$scenario' already attached",
            ),
        )
    end
    flow.profiles[key] = profile_value

    return flow
end

"""
    set_partition!(flow::TulipaFlow, year, rep_period, specification, partition)
    set_partition!(flow::TulipaFlow, year, rep_period, partition)

Internal version of `set_partition!` acting directly on a `TulipaFlow` object.
"""
function set_partition!(
    flow::TulipaFlow,
    year::Int,
    rep_period::Int,
    specification,
    partition,
)
    key = (year, rep_period)
    if haskey(flow.partitions, key)
        throw(
            ExistingKeyError(
                "Partition for year '$year' for rep_period '$rep_period' already set",
            ),
        )
    end
    flow.partitions[key] = Dict(:specification => specification, :partition => partition)

    return flow
end
set_partition!(flow::TulipaFlow, year::Int, rep_period::Int, partition) =
    set_partition!(flow, year, rep_period, "uniform", partition)
