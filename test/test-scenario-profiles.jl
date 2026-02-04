@testitem "Attach scenario profiles for assets" tags = [:unit, :fast] setup = [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Attach scenario profiles
    attach_profile!(tulipa, "producer", :availability, 2030, 1, ones(24))
    attach_profile!(tulipa, "producer", :availability, 2030, 2, 2 .* ones(24))

    # Verify that the profiles are stored correctly
    asset = tulipa.graph["producer"]
    @test haskey(asset.scenario_profiles, (:availability, 2030, 1))
    @test haskey(asset.scenario_profiles, (:availability, 2030, 2))
    @test asset.scenario_profiles[(:availability, 2030, 1)] == ones(24)
    @test asset.scenario_profiles[(:availability, 2030, 2)] == 2 .* ones(24)

    # Verify that year information is updated
    @test haskey(tulipa.years, 2030)
    @test tulipa.years[2030][:length] == 24
    @test tulipa.years[2030][:is_milestone] == true
end

@testitem "ExistingKeyError for duplicate scenario profiles" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Attach scenario profile
    attach_profile!(tulipa, "producer", :availability, 2030, 1, ones(24))

    # Try to attach the same scenario profile again
    @test_throws ExistingKeyError attach_profile!(
        tulipa,
        "producer",
        :availability,
        2030,
        1,
        ones(24),
    )

    # But we can attach a different scenario
    attach_profile!(tulipa, "producer", :availability, 2030, 2, ones(24))

    # And we can attach a non-scenario profile with the same profile_type and year (default scenario assigned)
    attach_profile!(tulipa, "producer", :demand, 2030, ones(24))
end

@testitem "Create connection with scenario profiles for assets" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrames, DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Attach multiple scenario profiles
    attach_profile!(tulipa, "producer", :availability, 2030, 1, ones(24))
    attach_profile!(tulipa, "producer", :availability, 2030, 2, 2 .* ones(24))
    attach_profile!(tulipa, "producer", :availability, 2030, 3, 3 .* ones(24))

    connection = create_connection(tulipa)

    # Check that assets_profiles has only one entry (no scenario column)
    assets_profiles_df =
        DuckDB.query(connection, "SELECT * FROM assets_profiles") |> DataFrame
    @test size(assets_profiles_df, 1) == 1  # Only one entry
    @test assets_profiles_df.asset[1] == "producer"
    @test assets_profiles_df.profile_type[1] == "availability"
    @test assets_profiles_df.commission_year[1] == 2030

    # Check that profiles has entries for all scenarios (with scenario column)
    profiles_df =
        DuckDB.query(connection, "SELECT * FROM profiles ORDER BY scenario, timestep") |>
        DataFrame
    @test size(profiles_df, 1) == 24 * 3  # 24 timesteps × 3 scenarios

    # Check scenario1
    scenario1_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = '1' ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario1_df, 1) == 24
    @test all(scenario1_df.scenario .== 1)
    @test all(scenario1_df.value .== 1.0)

    # Check scenario2
    scenario2_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = '2' ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario2_df, 1) == 24
    @test all(scenario2_df.scenario .== 2)
    @test all(scenario2_df.value .== 2.0)

    # Check scenario3
    scenario3_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = '3' ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario3_df, 1) == 24
    @test all(scenario3_df.scenario .== 3)
    @test all(scenario3_df.value .== 3.0)
end

@testitem "Create connection with mixed profiles (scenario and non-scenario)" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrames, DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)

    # Attach non-scenario profile for producer (default scenario is added)
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))

    # Attach scenario profiles for consumer
    attach_profile!(tulipa, "consumer", :demand, 2030, 1, ones(24))
    attach_profile!(tulipa, "consumer", :demand, 2030, 2, 2 .* ones(24))

    connection = create_connection(tulipa)

    # Check assets_profiles has two entries
    assets_profiles_df =
        DuckDB.query(connection, "SELECT * FROM assets_profiles ORDER BY asset") |>
        DataFrame
    @test size(assets_profiles_df, 1) == 2

    # Check profiles table
    profiles_df = DuckDB.query(connection, "SELECT * FROM profiles") |> DataFrame
    @test size(profiles_df, 1) == 24 + 24 * 2  # 24 (non-scenario using default scenario) + 48 (scenario)

    # Non-scenario profile should have default scenario
    non_scenario_df =
        DuckDB.query(
            connection,
            "SELECT *
            FROM profiles
            WHERE
                scenario = '1' AND
                profile_name = 'producer-availability-2030'
            ORDER BY timestep",
        ) |> DataFrame
    @test size(non_scenario_df, 1) == 24
    @test all(non_scenario_df.scenario .== 1) # Default scenario
    @test all(non_scenario_df.value .== 1.0)

    # Scenario 1 should have the availability profile (attached without scenario, so using default scenario)
    #  and the scenario 1 demand profile
    scenario1_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = '1' ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario1_df, 1) == 48  # 24 (availability) + 24 (demand)
    @test all(scenario1_df.value .== 1.0)

    # Scenario 2 should have only the demand profile
    scenario2_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = '2' ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario2_df, 1) == 24
    @test all(scenario2_df.value .== 2.0)
end

@testitem "API consistency for scenario attach_profile!" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    # Test that attach_profile! returns the tulipa object for chaining
    tulipa = TulipaData()
    add_asset!(tulipa, "producer1", :producer)

    @test attach_profile!(tulipa, "producer1", :availability, 2030, 1, rand(24)) === tulipa

    # Test that attach_profile! returns the asset object
    asset = tulipa.graph["producer1"]
    @test attach_profile!(asset, :availability, 2031, 1, rand(24)) === asset

end
