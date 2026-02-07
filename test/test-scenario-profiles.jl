@testitem "Attach scenario profiles for assets" tags = [:unit, :fast, :scenario] setup =
    [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Attach scenario profiles
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24); scenario = 1)
    attach_profile!(tulipa, "producer", :availability, 2030, 2 .* ones(24); scenario = 2)

    # Verify that the profiles are stored correctly
    asset = tulipa.graph["producer"]
    @test haskey(asset.profiles, (:availability, 2030, 1))
    @test haskey(asset.profiles, (:availability, 2030, 2))
    @test asset.profiles[(:availability, 2030, 1)] == ones(24)
    @test asset.profiles[(:availability, 2030, 2)] == 2 .* ones(24)

    # Verify that year information is updated
    @test haskey(tulipa.years, 2030)
    @test tulipa.years[2030][:length] == 24
    @test tulipa.years[2030][:is_milestone] == true
end

@testitem "Create connection with scenario profiles for assets" tags =
    [:unit, :fast, :scenario] setup = [CommonSetup, CreateConnectionSetup] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrames, DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Attach multiple scenario profiles
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24); scenario = 1)
    attach_profile!(tulipa, "producer", :availability, 2030, 2 .* ones(24); scenario = 2)
    attach_profile!(tulipa, "producer", :availability, 2030, 3 .* ones(24); scenario = 3)

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
            "SELECT * FROM profiles WHERE scenario = 1 ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario1_df, 1) == 24
    @test all(scenario1_df.scenario .== 1)
    @test all(scenario1_df.value .== 1.0)

    # Check scenario2
    scenario2_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = 2 ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario2_df, 1) == 24
    @test all(scenario2_df.scenario .== 2)
    @test all(scenario2_df.value .== 2.0)

    # Check scenario3
    scenario3_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = 3 ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario3_df, 1) == 24
    @test all(scenario3_df.scenario .== 3)
    @test all(scenario3_df.value .== 3.0)
end

@testitem "Create connection with mixed profiles (scenario and non-scenario)" tags =
    [:unit, :fast, :scenario] setup = [CommonSetup, CreateConnectionSetup] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrames, DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)

    # Attach non-scenario profile for producer (default scenario is added)
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))

    # Attach scenario profiles for consumer
    attach_profile!(tulipa, "consumer", :demand, 2030, ones(24); scenario = 1)
    attach_profile!(tulipa, "consumer", :demand, 2030, 2 .* ones(24); scenario = 2)

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
                scenario = 1 AND
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
            "SELECT * FROM profiles WHERE scenario = 1 ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario1_df, 1) == 48  # 24 (availability) + 24 (demand)
    @test all(scenario1_df.value .== 1.0)

    # Scenario 2 should have only the demand profile
    scenario2_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE scenario = 2 ORDER BY timestep",
        ) |> DataFrame
    @test size(scenario2_df, 1) == 24
    @test all(scenario2_df.value .== 2.0)
end

@testitem "Attach profiles for flows" tags = [:unit, :fast, :scenario] setup = [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")

    # Attach flow profile
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))

    # Verify that the profile is stored correctly (default scenario = 1)
    flow = tulipa.graph["producer", "consumer"]
    @test haskey(flow.profiles, (:inflows, 2030, 1))
    @test flow.profiles[(:inflows, 2030, 1)] == ones(24)

    # Verify that year information is updated
    @test haskey(tulipa.years, 2030)
    @test tulipa.years[2030][:length] == 24
    @test tulipa.years[2030][:is_milestone] == true

    # Verify duplicate flow profile throws error
    @test_throws ExistingKeyError attach_profile!(
        tulipa,
        "producer",
        "consumer",
        :inflows,
        2030,
        ones(24),
    )
end

@testitem "Attach scenario profiles for flows" tags = [:unit, :fast, :scenario] setup =
    [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")

    # Attach multiple scenario profiles for a flow
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24); scenario = 1)
    attach_profile!(
        tulipa,
        "producer",
        "consumer",
        :inflows,
        2030,
        2 .* ones(24);
        scenario = 2,
    )

    # Verify that the profiles are stored correctly
    flow = tulipa.graph["producer", "consumer"]
    @test haskey(flow.profiles, (:inflows, 2030, 1))
    @test haskey(flow.profiles, (:inflows, 2030, 2))
    @test flow.profiles[(:inflows, 2030, 1)] == ones(24)
    @test flow.profiles[(:inflows, 2030, 2)] == 2 .* ones(24)

    # Verify that duplicate scenario throws error
    @test_throws ExistingKeyError attach_profile!(
        tulipa,
        "producer",
        "consumer",
        :inflows,
        2030,
        ones(24);
        scenario = 1,
    )
end

@testitem "Create connection with flow profiles" tags = [:unit, :fast, :scenario] setup =
    [CommonSetup, CreateConnectionSetup] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrames, DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")

    # Attach flow profile
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))

    connection = create_connection(tulipa)

    # Check that flows_profiles table is created with one entry
    flows_profiles_df =
        DuckDB.query(connection, "SELECT * FROM flows_profiles") |> DataFrame
    @test size(flows_profiles_df, 1) == 1
    @test flows_profiles_df.from_asset[1] == "producer"
    @test flows_profiles_df.to_asset[1] == "consumer"
    @test flows_profiles_df.profile_type[1] == "inflows"

    # Check that profiles table has the flow profile data with default scenario
    profiles_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE profile_name = 'producer-consumer-inflows-2030' ORDER BY timestep",
        ) |> DataFrame
    @test size(profiles_df, 1) == 24
    @test all(profiles_df.value .== 1.0)
    @test all(profiles_df.scenario .== 1)
end

@testitem "Create connection with mixed asset scenario profiles and flow profiles" tags =
    [:unit, :fast, :scenario] setup = [CommonSetup, CreateConnectionSetup] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrames, DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")

    # Attach asset profiles with scenarios
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24); scenario = 1)
    attach_profile!(tulipa, "producer", :availability, 2030, 2 .* ones(24); scenario = 2)

    # Attach flow profile (uses default scenario = 1)
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, 3 .* ones(24))

    connection = create_connection(tulipa)

    # Check assets_profiles has one entry
    assets_profiles_df =
        DuckDB.query(connection, "SELECT * FROM assets_profiles") |> DataFrame
    @test size(assets_profiles_df, 1) == 1

    # Check flows_profiles has one entry
    flows_profiles_df =
        DuckDB.query(connection, "SELECT * FROM flows_profiles") |> DataFrame
    @test size(flows_profiles_df, 1) == 1

    # Check profiles table has all entries
    profiles_df = DuckDB.query(connection, "SELECT * FROM profiles") |> DataFrame
    @test size(profiles_df, 1) == 24 * 2 + 24  # 2 asset scenarios + 1 flow profile

    # Asset profiles should have scenario values
    asset_profiles_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE profile_name = 'producer-availability-2030' ORDER BY scenario, timestep",
        ) |> DataFrame
    @test size(asset_profiles_df, 1) == 48
    @test all(asset_profiles_df.scenario[1:24] .== 1)
    @test all(asset_profiles_df.value[1:24] .== 1.0)
    @test all(asset_profiles_df.scenario[25:48] .== 2)
    @test all(asset_profiles_df.value[25:48] .== 2.0)

    # Flow profile should have default scenario = 1
    flow_profiles_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles WHERE profile_name = 'producer-consumer-inflows-2030' ORDER BY timestep",
        ) |> DataFrame
    @test size(flow_profiles_df, 1) == 24
    @test all(flow_profiles_df.value .== 3.0)
    @test all(flow_profiles_df.scenario .== 1)
end
