mutable struct TulipaAsset
    name::Symbol
    type::AssetType

    basic_data::Dict{Symbol,Any}
    commission_year_data::PerYear{Dict{Symbol,Any}}
    milestone_year_data::PerYear{Dict{Symbol,Any}}
    both_years_data::PerYears{Dict{Symbol,Any}}

    profiles::Dict{Tuple{ProfileType,Int},Vector{Float64}}

    function TulipaAsset(asset_name::Union{Symbol,String}, type::Symbol; kwargs...)
        asset_name_symbol = Symbol(asset_name)
        return new(
            asset_name_symbol,
            type,
            Dict{Symbol,Any}(kwargs...),
            PerYear{Dict{Symbol,Any}}(),
            PerYear{Dict{Symbol,Any}}(),
            PerYears{Dict{Symbol,Any}}(),
            Dict(),
        )
    end
end

function attach_commission_data!(asset::TulipaAsset, year; kwargs...)
    asset.commission_year_data[year] = Dict{Symbol,Any}(kwargs...)
end

function attach_milestone_data!(asset::TulipaAsset, year; kwargs...)
    asset.milestone_year_data[year] = Dict{Symbol,Any}(kwargs...)
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

