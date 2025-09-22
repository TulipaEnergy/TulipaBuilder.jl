mutable struct TulipaAsset{KeyType}
    name::KeyType
    type::AssetType

    basic_data::Dict{Symbol,Any}
    commission_year_data::PerYear{Dict{Symbol,Any}}
    milestone_year_data::PerYear{Dict{Symbol,Any}}
    both_years_data::PerYears{Dict{Symbol,Any}}

    profiles::Dict{Tuple{ProfileType,Int},Vector{Float64}}

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

function attach_commission_data!(
    asset::TulipaAsset,
    year;
    on_conflict = :overwrite,
    kwargs...,
)
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

function attach_milestone_data!(
    asset::TulipaAsset,
    year;
    on_conflict = :overwrite,
    kwargs...,
)
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

function attach_both_years_data!(
    asset::TulipaAsset,
    commission_year,
    milestone_year;
    kwargs...,
)
    @assert milestone_year ≥ commission_year
    asset.both_years_data[(commission_year, milestone_year)] = Dict{Symbol,Any}(kwargs...)
end

function attach_profile!(
    asset::TulipaAsset,
    profile_type::ProfileType,
    year::Int,
    profile_value::Vector,
)
    asset.profiles[(profile_type, year)] = profile_value
end
