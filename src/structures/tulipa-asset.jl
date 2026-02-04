
"""
Internal structure to hold all information of a given asset.
It's used internally inside the graph that's inside the TulipaData object.
"""
mutable struct TulipaAsset{KeyType}
    name::KeyType
    type::AssetType

    basic_data::Dict{Symbol,Any}
    commission_year_data::PerYear{Dict{Symbol,Any}}
    milestone_year_data::PerYear{Dict{Symbol,Any}}
    both_years_data::PerYears{Dict{Symbol,Any}}

    profiles::Dict{Tuple{ProfileType,Int},Vector{Float64}}
    scenario_profiles::Dict{Tuple{ProfileType,Int,ScenarioType},Vector{Float64}}

    partitions::Dict{Tuple{Int,Int},Dict{Symbol,Any}}

    """
        TulipaAsset(asset_name, type; kwargs...)

    Create a new `TulipaAsset` with given name `asset_name`, type `type`, and
    further values provided by the keyword arguments.
    """
    function TulipaAsset(asset_name::KeyType, type::AssetType; kwargs...) where {KeyType}
        return new{KeyType}(
            asset_name,
            type,
            Dict{Symbol,Any}(kwargs...),
            PerYear{Dict{Symbol,Any}}(),
            PerYear{Dict{Symbol,Any}}(),
            PerYears{Dict{Symbol,Any}}(),
            Dict(),
            Dict(),
            Dict(),
        )
    end
end

"""
    attach_commission_data!(asset::TulipaAsset, year; kwargs...)

Internal version of `attach_commission_data!` acting directly on a `TulipaAsset`
object.
"""
function attach_commission_data!(
    asset::TulipaAsset,
    year;
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
    # If the year has not been set, then it is not possible to have conflicts
    if !haskey(asset.commission_year_data, year)
        asset.commission_year_data[year] = Dict{Symbol,Any}(kwargs...)
        return asset
    end

    for (k, v) in kwargs
        # Either the key already exists or it is allowed to s
        if !haskey(asset.commission_year_data[year], k) || on_conflict == :overwrite
            asset.commission_year_data[year][k] = v
        elseif on_conflict == :error
            throw(
                ExistingKeyError(
                    "Key $k has already been attached for asset=$(asset.name), commission_year=$year",
                ),
            )
        end # on_conflict = :skip
    end
    return asset
end

"""
    attach_milestone_data!(asset::TulipaAsset, year; kwargs...)

Internal version of `attach_milestone_data!` acting directly on a `TulipaAsset`
object.
"""
function attach_milestone_data!(
    asset::TulipaAsset,
    year;
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
    # If the year has not been set, then it is not possible to have conflicts
    if !haskey(asset.milestone_year_data, year)
        asset.milestone_year_data[year] = Dict{Symbol,Any}(kwargs...)
        return asset
    end

    for (k, v) in kwargs
        # Either the key already exists or it is allowed to be overwritten
        if !haskey(asset.milestone_year_data[year], k) || on_conflict == :overwrite
            asset.milestone_year_data[year][k] = v
        elseif on_conflict == :error
            throw(
                ExistingKeyError(
                    "Key $k has already been attached for asset=$(asset.name), milestone_year=$year",
                ),
            )
        end # on_conflict = :skip
    end
    return asset
end

"""
    attach_both_years_data!(asset::TulipaAsset, commission_year, milestone_year; kwargs...)

Internal version of `attach_both_years_data!` acting directly on a `TulipaAsset`
object.
"""
function attach_both_years_data!(
    asset::TulipaAsset,
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
    if !haskey(asset.both_years_data, year_key)
        asset.both_years_data[year_key] = Dict{Symbol,Any}(kwargs...)
        return asset
    end

    for (k, v) in kwargs
        # Either the key already exists or it is allowed to be overwritten
        if !haskey(asset.both_years_data[year_key], k) || on_conflict == :overwrite
            asset.both_years_data[year_key][k] = v
        elseif on_conflict == :error
            throw(
                ExistingKeyError(
                    "Key $k has already been attached for asset=$(asset.name), milestone_year=$milestone_year, commission_year=$commission_year",
                ),
            )
        end # on_conflict = :skip
    end
    return asset
end

"""
    attach_profile!(asset::TulipaAsset, profile_type, year, profile_value)

Internal version of `attach_profile!` acting directly on a `TulipaAsset` object.
"""
function attach_profile!(
    asset::TulipaAsset,
    profile_type::ProfileType,
    year::Int,
    profile_value::Vector,
)
    key = (profile_type, year)
    if haskey(asset.profiles, key)
        throw(
            ExistingKeyError(
                "Profile of type '$profile_type' for year '$year' already attached",
            ),
        )
    end
    asset.profiles[key] = profile_value

    return asset
end

"""
    attach_profile!(asset::TulipaAsset, profile_type, year, scenario, profile_value)

Internal version of `attach_profile!` with scenario support acting directly on a `TulipaAsset` object.
"""
function attach_profile!(
    asset::TulipaAsset,
    profile_type::ProfileType,
    year::Int,
    scenario::ScenarioType,
    profile_value::Vector,
)
    key = (profile_type, year, scenario)
    if haskey(asset.scenario_profiles, key)
        throw(
            ExistingKeyError(
                "Profile of type '$profile_type' for year '$year' and scenario '$scenario' already attached",
            ),
        )
    end
    asset.scenario_profiles[key] = profile_value

    return asset
end

"""
    set_partition!(asset::TulipaAsset, year, rep_period, specification, partition)
    set_partition!(asset::TulipaAsset, year, rep_period, partition)

Internal version of `set_partition!` acting directly on a `TulipaAsset` object.
"""
function set_partition!(
    asset::TulipaAsset,
    year::Int,
    rep_period::Int,
    specification,
    partition,
)
    key = (year, rep_period)
    if haskey(asset.partitions, key)
        throw(
            ExistingKeyError(
                "Partition for year '$year' for rep_period '$rep_period' already set",
            ),
        )
    end
    asset.partitions[key] = Dict(:specification => specification, :partition => partition)

    return asset
end
set_partition!(asset::TulipaAsset, year::Int, rep_period::Int, partition) =
    set_partition!(asset, year, rep_period, "uniform", partition)
