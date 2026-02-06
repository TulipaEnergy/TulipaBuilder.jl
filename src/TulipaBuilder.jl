module TulipaBuilder

using DataFrames: DataFrames, DataFrame
using DuckDB: DuckDB, DBInterface
using Graphs: Graphs
using MetaGraphsNext: MetaGraphsNext
using TulipaEnergyModel: TulipaEnergyModel as TEM
using TulipaIO: TulipaIO as TIO

const AssetType = Symbol
const ProfileType = Symbol
const ScenarioType = Int
const DEFAULT_SCENARIO = 1
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

# output functions
include("output.jl")

end
