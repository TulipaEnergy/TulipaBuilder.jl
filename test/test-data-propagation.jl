@testitem "Test that passing asset_both properties to add_asset propagates correctly" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :asset1, :producer, initial_units = 100.0)
    add_asset!(tulipa, :asset2, :producer)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)

    connection = create_connection(tulipa, TEM.schema)
    initial_units = Dict("asset1" => 100.0, "asset2" => 0.0) # 0.0 is the default
    for row in DuckDB.query(connection, "FROM asset_both")
        @test row.initial_units == initial_units[row.asset]
    end
    close(connection)
end

@testitem "Compact and semi-compact assets do not get asset_both auto-propagated" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :simple, :producer, investment_method = "simple")
    add_asset!(tulipa, :compact_asset, :producer, investment_method = "compact")
    add_asset!(tulipa, :semi, :producer, investment_method = "semi-compact")
    add_asset!(tulipa, :none_asset, :producer, investment_method = "none")
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)

    connection = create_connection(tulipa, TEM.schema)
    asset_both_assets =
        Set(row.asset for row in DuckDB.query(connection, "FROM asset_both"))
    @test "simple" in asset_both_assets
    @test "none_asset" in asset_both_assets
    @test !("compact_asset" in asset_both_assets)
    @test !("semi" in asset_both_assets)
    close(connection)
end

@testitem "Commission years without explicit data do not appear in commission tables" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :asset1, :producer)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)
    tulipa.years[2020] = Dict(:length => 1, :is_milestone => false)  # commission year, no data

    connection = create_connection(tulipa, TEM.schema)

    milestone_rows = collect(DuckDB.query(connection, "FROM asset_milestone"))
    commission_rows = collect(DuckDB.query(connection, "FROM asset_commission"))

    # Only milestone year gets a row in asset_milestone
    @test length(milestone_rows) == 1
    @test milestone_rows[1].milestone_year == 2025

    # Commission year with no explicit data is not auto-created in asset_commission
    @test length(commission_rows) == 1
    @test commission_rows[1].commission_year == 2025

    close(connection)
end

@testitem "Basic data propagates to commission years that have explicit entries" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :producer, :producer)
    add_asset!(tulipa, :consumer, :consumer)
    add_flow!(tulipa, :producer, :consumer, investment_cost = 500.0)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)
    tulipa.years[2020] = Dict(:length => 1, :is_milestone => false)  # commission year

    # Register year 2020 as a commission year — no need to duplicate investment_cost
    attach_commission_data!(tulipa, :producer, :consumer, 2020)

    connection = create_connection(tulipa, TEM.schema)

    commission_rows = Dict(
        row.commission_year => row for
        row in DuckDB.query(connection, "FROM flow_commission")
    )

    @test haskey(commission_rows, 2025)
    @test haskey(commission_rows, 2020)
    # investment_cost from add_flow! is propagated to all commission years
    @test commission_rows[2025].investment_cost == 500.0
    @test commission_rows[2020].investment_cost == 500.0

    close(connection)
end

@testitem "Basic data from add_asset propagates to asset_commission for milestone years" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :asset1, :producer, investment_cost = 100.0)
    add_asset!(tulipa, :asset2, :producer)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)

    connection = create_connection(tulipa, TEM.schema)

    commission_rows =
        Dict(row.asset => row for row in DuckDB.query(connection, "FROM asset_commission"))
    @test commission_rows["asset1"].investment_cost == 100.0
    @test commission_rows["asset2"].investment_cost == 0.0  # schema default

    close(connection)
end

@testitem "Basic data propagates to asset_commission years that have explicit entries" setup =
    [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :asset1, :producer, investment_cost = 100.0)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)
    tulipa.years[2020] = Dict(:length => 1, :is_milestone => false)  # commission year

    # Register year 2020 as a commission year — no need to duplicate investment_cost
    attach_commission_data!(tulipa, :asset1, 2020)

    connection = create_connection(tulipa, TEM.schema)

    commission_rows = Dict(
        row.commission_year => row for
        row in DuckDB.query(connection, "FROM asset_commission")
    )

    @test haskey(commission_rows, 2025)
    @test haskey(commission_rows, 2020)
    # investment_cost from add_asset! is propagated to all commission years
    @test commission_rows[2025].investment_cost == 100.0
    @test commission_rows[2020].investment_cost == 100.0

    close(connection)
end

@testitem "Test propagation from add_flow" setup = [CommonSetup] tags = [:unit, :fast] begin
    tulipa = TulipaData{Symbol}()
    add_asset!(tulipa, :prod1, :producer)
    add_asset!(tulipa, :prod2, :producer)
    add_asset!(tulipa, :prod3, :producer)
    add_asset!(tulipa, :dem, :consumer)
    add_flow!(tulipa, :prod1, :dem, operational_cost = 1.0)
    add_flow!(
        tulipa,
        :prod2,
        :dem,
        decommissionable = true,
        fixed_cost = 5.0,
        is_transport = true,
    )
    add_flow!(tulipa, :prod3, :dem, decommissionable = false, is_transport = true)
    tulipa.years[2025] = Dict(:length => 1, :is_milestone => true)

    connection = create_connection(tulipa, TEM.schema)
    decommissionable = Dict(("prod2", "dem") => true, ("prod3", "dem") => false)
    fixed_cost =
        Dict(("prod1", "dem") => 0.0, ("prod2", "dem") => 5.0, ("prod3", "dem") => 0.0)
    operational_cost =
        Dict(("prod1", "dem") => 1.0, ("prod2", "dem") => 0.0, ("prod3", "dem") => 0.0)
    for row in DuckDB.query(connection, "FROM flow_commission")
        @test row.fixed_cost == fixed_cost[(row.from_asset, row.to_asset)]
    end
    for row in DuckDB.query(connection, "FROM flow_milestone")
        @test row.operational_cost == operational_cost[(row.from_asset, row.to_asset)]
    end
    flow_both_rows = collect(DuckDB.query(connection, "FROM flow_both"))
    @test length(flow_both_rows) == length(decommissionable)
    for row in flow_both_rows
        @test row.decommissionable == decommissionable[(row.from_asset, row.to_asset)]
    end
end
