using DataFrames
using XLSX
using TulipaBuilder
using Test

@testset "TulipaBuilder.jl" begin
    tulipa = TulipaData()
    add_asset!(tulipa, :ccgt, :producer, capacity = 225)
    add_asset!(
        tulipa,
        :solar,
        :producer,
        description = "Stuff",
        capacity = 10.0,
        resolution = 6,
    )
    add_asset!(tulipa, :ocgt, :producer, capacity = 25.0, investment_method = "simple")

    add_asset!(tulipa, :demand, :consumer)

    add_flow!(tulipa, :solar, :demand, capacity = 10.0)
    for asset in (:ccgt, :ocgt)
        add_flow!(tulipa, asset, :demand, capacity = 5.0)
    end

    xls = XLSX.readxlsx(joinpath(@__DIR__, "tulipatest.xlsx"))
    profiles_df = DataFrame(XLSX.gettable(xls["profiles"]))

    attach_profile!(tulipa, :solar, :availability, profiles_df[!, "Solar"])

    attach_profile!(tulipa, :demand, :demand, profiles_df[!, "Demand"])

    attach_profile!(tulipa, :ccgt, :availability, 0.5 .+ 0.1 * randn(24))

    # no profile for ocgt
end
