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
