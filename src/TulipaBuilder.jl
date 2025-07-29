module TulipaBuilder

export TulipaAsset,
    TulipaFlow,
    TulipaData,
    add_asset!,
    add_flow!,
    attach_profile!,
    attach_commission_data!,
    attach_milestone_data!,
    attach_both_years_data!

using DataFrames: DataFrames, DataFrame
using DuckDB: DuckDB, DBInterface
using Graphs: Graphs
using MetaGraphsNext: MetaGraphsNext
using TulipaClustering: TulipaClustering as TC
using TulipaEnergyModel: TulipaEnergyModel as TEM
using TulipaIO: TulipaIO as TIO

const AssetType = Symbol
const ProfileType = Symbol
const PerYear{T} = Dict{Int,T}
const PerYears{T} = Dict{Tuple{Int,Int},T}
const PerProfileType{T} = Dict{ProfileType,T}

# utils
include("utils.jl")

# structures
include("structures/tulipa-asset.jl")
include("structures/tulipa-flow.jl")
include("structures/tulipa-data.jl")

# conversion to TulipaEnergyModel format
include("create-connection.jl")

end
