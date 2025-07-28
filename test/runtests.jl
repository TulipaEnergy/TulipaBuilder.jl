using DataFrames
using JuMP
using TulipaBuilder
using TulipaEnergyModel
using Test

@testset "TulipaBuilder.jl" begin
    tulipa = TulipaData()

    ### assets
    add_asset!(tulipa, :ccgt, :producer, capacity = 2.0, investment_method = "simple")
    attach_milestone_data!(tulipa, :ccgt, 2030, investable = true)
    attach_commission_data!(tulipa, :ccgt, 2030, investment_cost = 3.0)

    add_asset!(
        tulipa,
        :solar,
        :producer,
        description = "Solar",
        capacity = 1.0,
        resolution = 6,
    )
    attach_both_years_data!(tulipa, :solar, 2030, 2030, initial_units = 10)

    add_asset!(tulipa, :ocgt, :producer, capacity = 3.0, investment_method = "simple")
    attach_milestone_data!(tulipa, :ocgt, 2030, investable = true)
    attach_commission_data!(tulipa, :ocgt, 2030, investment_cost = 4.0)

    add_asset!(tulipa, :demand, :consumer)
    attach_milestone_data!(tulipa, :demand, 2030, peak_demand = 30.0)

    ### flows
    add_flow!(tulipa, :solar, :demand)
    for asset in (:ccgt, :ocgt)
        add_flow!(tulipa, asset, :demand)
    end

    ### profiles
    domain = range(0.0, 1.0, length = 24)
    attach_profile!(tulipa, :solar, :availability, 2030, 4 * domain .* (1 .- domain))
    attach_profile!(tulipa, :demand, :demand, 2030, 0.5 .+ 0.1 * randn(24))
    attach_profile!(tulipa, :ccgt, :availability, 2030, rand(0.1:0.1:0.9, 24))
    # no profile for ocgt

    connection = create_connection(tulipa)

    # External
    ep = TulipaEnergyModel.run_scenario(
        connection,
        show_log = false,
        model_file_name = "model.lp",
    )
    @test JuMP.is_solved_and_feasible(ep.model)
end

# Test warning for ignored column
