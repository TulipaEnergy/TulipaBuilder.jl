
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
    asset.profiles[(profile_type, year)] = profile_value
end
