@testitem "Test that passing asset_both properties to add_asset propagates correctly" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :asset1, :producer, initial_units = 100.0)
    add_asset!(tulipa, :asset2, :producer)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)

    connection = create_connection(tulipa)
    initial_units = Dict("asset1" => 100.0, "asset2" => 0.0) # 0.0 is the default
    for row in DuckDB.query(connection, "FROM asset_both")
        @test row.initial_units == initial_units[row.asset]
    end
    close(connection)
end

@testitem "Test propagation from add_flow" setup = [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :prod1, :producer)
    add_asset!(tulipa, :prod2, :producer)
    add_asset!(tulipa, :dem, :consumer)
    add_flow!(tulipa, :prod1, :dem, operational_cost = 1.0)
    add_flow!(tulipa, :prod2, :dem, decommissionable = true, fixed_cost = 5.0)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)

    connection = create_connection(tulipa)
    decommissionable = Dict(("prod1", "dem") => false, ("prod2", "dem") => true)
    fixed_cost = Dict(("prod1", "dem") => 0.0, ("prod2", "dem") => 5.0)
    operational_cost = Dict(("prod1", "dem") => 1.0, ("prod2", "dem") => 0.0)
    for row in DuckDB.query(connection, "FROM flow_commission")
        @test row.fixed_cost == fixed_cost[(row.from_asset, row.to_asset)]
    end
    for row in DuckDB.query(connection, "FROM flow_milestone")
        @test row.operational_cost == operational_cost[(row.from_asset, row.to_asset)]
    end
    # Currently ignoring flow_both
    # for row in DuckDB.query(connection, "FROM flow_both")
    #     @test row.decommissionable == decommissionable[(row.from_asset, row.to_asset)]
    # end
end
