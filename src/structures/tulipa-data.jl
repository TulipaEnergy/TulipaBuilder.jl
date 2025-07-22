export TulipaData

mutable struct TulipaData
    graph::MetaGraphsNext.MetaGraph
    validated::Bool

    years::PerYear{Dict{Symbol,Any}}

    function TulipaData()
        graph = MetaGraphsNext.MetaGraph(
            Graphs.DiGraph(),
            label_type = Symbol,
            vertex_data_type = TulipaAsset,
            edge_data_type = TulipaFlow,
        )

        return new(graph, false, Dict())
    end
end

function add_or_update_year!(tulipa::TulipaData, year::Int; kwargs...)
    if !haskey(tulipa.years, year)
        tulipa.years[year] = Dict{Symbol,Any}()
    end
    for (key, value) in kwargs
        tulipa.years[year][key] = value
    end

    return tulipa
end

function add_asset!(tulipa::TulipaData, asset::TulipaAsset)
    if haskey(tulipa.graph, asset.name)
        error("Asset exists")
    end
    tulipa.graph[asset.name] = asset

    return tulipa
end

function add_asset!(
    tulipa::TulipaData,
    asset_name,
    type;
    kwargs..., # fields of table asset?
)
    asset = TulipaAsset(asset_name, type; kwargs...)
    add_asset!(tulipa, asset)
end

function attach_commission_data!(
    tulipa::TulipaData,
    asset,
    year;
    kwargs..., # fields of commission
)
    add_or_update_year!(tulipa, year)
    attach_commission_data!(tulipa.graph[asset], year; kwargs...)
end

function attach_milestone_data!(
    tulipa::TulipaData,
    asset,
    year;
    kwargs..., # fields of milestone
)
    add_or_update_year!(tulipa, year, is_milestone = true)
    attach_milestone_data!(tulipa.graph[asset], year; kwargs...)
end

function attach_both_years_data!(
    tulipa::TulipaData,
    asset,
    commission_year,
    milestone_year;
    kwargs..., # fields of both_years
)
    add_or_update_year!(tulipa, commission_year)
    add_or_update_year!(tulipa, milestone_year, is_milestone = true)
    attach_both_years_data!(tulipa.graph[asset], commission_year, milestone_year; kwargs...)
end

function add_flow!(tulipa::TulipaData, flow::TulipaFlow)
    if haskey(tulipa.graph, flow.from, flow.to)
        error("Flow exists")
    end
    tulipa.graph[flow.from, flow.to] = flow

    return tulipa
end

function add_flow!(tulipa::TulipaData, from_asset_name, to_asset_name; kwargs...)
    flow = TulipaFlow(from_asset_name, to_asset_name; kwargs...)
    add_flow!(tulipa, flow)
end

function attach_commission_data!(
    tulipa::TulipaData,
    from_asset,
    to_asset,
    year;
    kwargs..., # fields of commission
)
    add_or_update_year!(tulipa, year)
    attach_commission_data!(tulipa.graph[from_asset, to_asset], year; kwargs...)
end

function attach_milestone_data!(
    tulipa::TulipaData,
    from_asset,
    to_asset,
    year;
    kwargs..., # fields of milestone
)
    add_or_update_year!(tulipa, year, is_milestone = true)
    attach_milestone_data!(tulipa.graph[from_asset, to_asset], year; kwargs...)
end

function attach_both_years_data!(
    tulipa::TulipaData,
    from_asset,
    to_asset,
    commission_year,
    milestone_year;
    kwargs..., # fields of both_years
)
    add_or_update_year!(tulipa, commission_year)
    add_or_update_year!(tulipa, milestone_year, is_milestone = true)
    attach_both_years_data!(
        tulipa.graph[from_asset, to_asset],
        commission_year,
        milestone_year;
        kwargs...,
    )
end

function attach_profile!(
    tulipa::TulipaData,
    asset_name,
    profile_type::ProfileType,
    year::Int,
    profile_value::Vector,
)
    add_or_update_year!(tulipa, year, length = length(profile_value))
    asset = tulipa.graph[asset_name]
    attach_profile!(asset, profile_type, year, profile_value)
end

