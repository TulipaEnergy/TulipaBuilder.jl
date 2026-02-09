export TulipaData,
    add_or_update_year!,
    add_asset!,
    add_flow!,
    attach_commission_data!,
    attach_milestone_data!,
    attach_both_years_data!,
    attach_profile!,
    add_asset_group!,
    set_partition!

"""
Main structure to hold all tulipa data.
"""
mutable struct TulipaData{KeyType}
    graph::MetaGraphsNext.MetaGraph
    validated::Bool

    years::PerYear{Dict{Symbol,Any}}

    asset_groups::Dict{Tuple{String,Int},Dict{Symbol,Any}}

    """
        TulipaData{KeyType}()
        TulipaData()

    Create a new `TulipaData` object with the key type `KeyType`.
    If ommitted, the `String` type is used.
    """
    function TulipaData{KeyType}() where {KeyType}
        graph = MetaGraphsNext.MetaGraph(
            Graphs.DiGraph(),
            label_type = KeyType,
            vertex_data_type = TulipaAsset,
            edge_data_type = TulipaFlow,
        )

        return new{KeyType}(graph, false, Dict(), Dict())
    end
end

TulipaData() = TulipaData{String}()

"""
    add_or_update_year!(tulipa_data, year; kwargs...)

Add `year`, or updates its information, using the provided keyword arguments.
"""
function add_or_update_year!(tulipa::TulipaData, year::Int; kwargs...)
    if !haskey(tulipa.years, year)
        tulipa.years[year] = Dict{Symbol,Any}()
    end
    for (key, value) in kwargs
        tulipa.years[year][key] = value
    end

    return tulipa
end

"""
    add_asset!(tulipa_data, asset::TulipaAsset)

Add `asset` to the tulipa data.
This version of the function is mostly for internal use, but it is part of the
public API.
"""
function add_asset!(tulipa::TulipaData, asset::TulipaAsset)
    if haskey(tulipa.graph, asset.name)
        throw(ExistingKeyError("Asset exists"))
    end
    tulipa.graph[asset.name] = asset

    return tulipa
end

"""
    add_asset!(tulipa_data, asset_name, type; kwargs...)

Add a new asset named `asset_name` of type `type` with data provided by the
keyword arguments.
The keywords can be any of the fields in the `asset`, `asset_milestone`,
`asset_commission`, and `asset_both` tables.

For multi-year problems, the data will be propagated for each year, even those
yet undefined.
"""
function add_asset!(
    tulipa::TulipaData,
    asset_name,
    type;
    kwargs..., # fields of table asset?
)
    asset = TulipaAsset(asset_name, type; kwargs...)
    add_asset!(tulipa, asset)
end

"""
    attach_commission_data!(tulipa_data, asset_name, year; kwargs...)

Set data of the asset named `asset_name` and commission year `year` provided by
the keyword arguments.
The keywords must be fields in the `asset_commission` table, or:

- `on_conflict`: (Default: `:overwrite`) How to handle key conflicts. Expected values are
  - `:error`: Raise an [`ExistingKeyError`](@ref)
  - `:overwrite`: Replace existing value
  - `:skip`: Ignore the key
"""
function attach_commission_data!(
    tulipa::TulipaData{KeyType},
    asset_name::KeyType,
    year;
    kwargs..., # fields of commission
) where {KeyType}
    add_or_update_year!(tulipa, year)
    attach_commission_data!(tulipa.graph[asset_name], year; kwargs...)
    return tulipa
end

"""
    attach_milestone_data!(tulipa_data, asset_name, year; kwargs...)

Set data of the asset named `asset_name` and milestone year `year` provided by
the keyword arguments.
The keywords must be fields in the `asset_milestone` table, or:

- `on_conflict`: (Default: `:overwrite`) How to handle key conflicts. Expected values are
  - `:error`: Raise an [`ExistingKeyError`](@ref)
  - `:overwrite`: Replace existing value
  - `:skip`: Ignore the key
"""
function attach_milestone_data!(
    tulipa::TulipaData{KeyType},
    asset_name::KeyType,
    year;
    kwargs..., # fields of milestone
) where {KeyType}
    add_or_update_year!(tulipa, year, is_milestone = true)
    attach_milestone_data!(tulipa.graph[asset_name], year; kwargs...)
    return tulipa
end

"""
    attach_both_yeards_data!(tulipa_data, asset_name, commission_year,
        milestone_year; kwargs...)

Set data of the asset named `asset_name` and the combination of years
`commission_year` and `milestone_year` provided by the keyword arguments.
The keywords must be fields in the `asset_both` table, or:

- `on_conflict`: (Default: `:overwrite`) How to handle key conflicts. Expected values are
  - `:error`: Raise an [`ExistingKeyError`](@ref)
  - `:overwrite`: Replace existing value
  - `:skip`: Ignore the key
"""
function attach_both_years_data!(
    tulipa::TulipaData{KeyType},
    asset_name::KeyType,
    commission_year,
    milestone_year;
    kwargs..., # fields of both_years
) where {KeyType}
    add_or_update_year!(tulipa, commission_year)
    add_or_update_year!(tulipa, milestone_year, is_milestone = true)
    attach_both_years_data!(
        tulipa.graph[asset_name],
        commission_year,
        milestone_year;
        kwargs...,
    )
    return tulipa
end

"""
    add_flow!(tulipa_data, flow::TulipaFlow)

Add `flow` to the tulipa data.
This version of the function is mostly for internal use, but it is part of the
public API.
"""
function add_flow!(tulipa::TulipaData, flow::TulipaFlow)
    if haskey(tulipa.graph, flow.from, flow.to)
        throw(ExistingKeyError("Flow exists"))
    end
    tulipa.graph[flow.from, flow.to] = flow

    return tulipa
end

"""
    add_flow!(tulipa_data, from_asset_name, to_asset_name; kwargs...)

Add a new flow between the assets named `from_asset_name` and `to_asset_name`
with data provided by the keyword arguments.
The keywords can be any of the fields in the `flow`, `flow_milestone`,
`flow_commission`, and `flow_both` tables.

For multi-year problems, the data will be propagated for each year, even those
yet undefined.
"""
function add_flow!(tulipa::TulipaData, from_asset_name, to_asset_name; kwargs...)
    flow = TulipaFlow(from_asset_name, to_asset_name; kwargs...)
    add_flow!(tulipa, flow)
end

"""
    attach_commission_data!(tulipa_data, from_asset_name, to_asset_name, year; kwargs...)

Set data of the flow `(from_asset_name, to_asset_name)` and commission year
`year` provided by the keyword arguments.
The keywords must be fields in the `flow_commission` table.
"""
function attach_commission_data!(
    tulipa::TulipaData{KeyType},
    from_asset_name::KeyType,
    to_asset_name::KeyType,
    year;
    kwargs..., # fields of commission
) where {KeyType}
    add_or_update_year!(tulipa, year)
    attach_commission_data!(tulipa.graph[from_asset_name, to_asset_name], year; kwargs...)
    return tulipa
end

"""
    attach_milestone_data!(tulipa_data, from_asset_name, to_asset_name, year; kwargs...)

Set data of the flow `(from_asset_name, to_asset_name)` and milestone year
`year` provided by the keyword arguments.
The keywords must be fields in the `flow_milestone` table.
"""
function attach_milestone_data!(
    tulipa::TulipaData{KeyType},
    from_asset_name::KeyType,
    to_asset_name::KeyType,
    year;
    kwargs..., # fields of milestone
) where {KeyType}
    add_or_update_year!(tulipa, year, is_milestone = true)
    attach_milestone_data!(tulipa.graph[from_asset_name, to_asset_name], year; kwargs...)
    return tulipa
end

"""
    attach_both_years_data!(tulipa_data, from_asset_name, to_asset_name,
        commission_year, milestone_year; kwargs...)

Set data of the flow `(from_asset_name, to_asset_name)` and the combination of years
`commission_year` and `milestone_year` provided by the keyword arguments.
The keywords must be fields in the `flow_both` table.
"""
function attach_both_years_data!(
    tulipa::TulipaData{KeyType},
    from_asset_name::KeyType,
    to_asset_name::KeyType,
    commission_year,
    milestone_year;
    kwargs..., # fields of both_years
) where {KeyType}
    add_or_update_year!(tulipa, commission_year)
    add_or_update_year!(tulipa, milestone_year, is_milestone = true)
    attach_both_years_data!(
        tulipa.graph[from_asset_name, to_asset_name],
        commission_year,
        milestone_year;
        kwargs...,
    )
    return tulipa
end

"""
    attach_profile!(tulipa_data, asset_name, profile_type, year, profile_value)

Attach the profile vector `profile_value` to the asset named `asset_name` of
the type `profile_type` for the year `year`.

This will also inform the length of the year using the length of the `profile_value`.
"""
function attach_profile!(
    tulipa::TulipaData{KeyType},
    asset_name::KeyType,
    profile_type::ProfileType,
    year::Int,
    profile_value::Vector;
    scenario::Int = DEFAULT_SCENARIO,
) where {KeyType}
    add_or_update_year!(tulipa, year, length = length(profile_value), is_milestone = true)
    asset = tulipa.graph[asset_name]
    attach_profile!(asset, profile_type, year, profile_value; scenario = scenario)
    return tulipa
end

"""
    attach_profile!(tulipa_data, from_asset_name, to_asset_name, profile_type, year, profile_value)

Attach the profile vector `profile_value` to the flow between `from_asset_name` and `to_asset_name` of
the type `profile_type` for the year `year`.

This will also inform the length of the year using the length of the `profile_value`.
"""
function attach_profile!(
    tulipa::TulipaData{KeyType},
    from_asset_name::KeyType,
    to_asset_name::KeyType,
    profile_type::ProfileType,
    year::Int,
    profile_value::Vector;
    scenario::Int = DEFAULT_SCENARIO,
) where {KeyType}
    add_or_update_year!(tulipa, year, length = length(profile_value), is_milestone = true)
    flow = tulipa.graph[from_asset_name, to_asset_name]
    attach_profile!(flow, profile_type, year, profile_value; scenario = scenario)
    return tulipa
end

"""
    add_asset_group!(tulipa_data, group_name, year; kwargs...)


Add a new asset group `group_name` for the given `year`.
"""
function add_asset_group!(
    tulipa::TulipaData{KeyType},
    group_name::KeyType,
    year::Int;
    kwargs...,
) where {KeyType}
    if haskey(tulipa.asset_groups, (group_name, year))
        throw(ExistingKeyError("Group asset exists"))
    end
    tulipa.asset_groups[(group_name, year)] = Dict{Symbol,Any}(kwargs...)

    return tulipa
end

"""
    set_partition!(tulipa_data, asset_name, year, rep_period, specification, partition)
    set_partition!(tulipa_data, asset_name, year, rep_period, partition)
    set_partition!(tulipa_data, from_asset_name, to_asset_name, year, rep_period, specification, partition)
    set_partition!(tulipa_data, from_asset_name, to_asset_name, year, rep_period, partition)

Set partition of the asset named `asset_name` or the flow `(from_asset_name, to_asset_name)`.
In both cases, if `specification` is ommitted, then `"uniform"` is used.

Notice that the representative period `rep_period` is expected, even though no
other part of the code deals with it, because partitions are tied to
clustering. This might change in the future.
"""
function set_partition!(
    tulipa::TulipaData{KeyType},
    asset_name::KeyType,
    year::Int,
    rep_period::Int,
    specification,
    partition,
) where {KeyType}
    asset = tulipa.graph[asset_name]
    set_partition!(asset, year, rep_period, specification, partition)

    return tulipa
end
set_partition!(
    tulipa::TulipaData{KeyType},
    asset_name::KeyType,
    year::Int,
    rep_period::Int,
    partition,
) where {KeyType} =
    set_partition!(tulipa, asset_name, year, rep_period, "uniform", partition)

function set_partition!(
    tulipa::TulipaData{KeyType},
    from_asset_name::KeyType,
    to_asset_name::KeyType,
    year::Int,
    rep_period::Int,
    specification,
    partition,
) where {KeyType}
    flow = tulipa.graph[from_asset_name, to_asset_name]
    set_partition!(flow, year, rep_period, specification, partition)

    return tulipa
end
set_partition!(
    tulipa::TulipaData{KeyType},
    from_asset_name::KeyType,
    to_asset_name::KeyType,
    year::Int,
    rep_period::Int,
    partition,
) where {KeyType} = set_partition!(
    tulipa,
    from_asset_name,
    to_asset_name,
    year,
    rep_period,
    "uniform",
    partition,
)
