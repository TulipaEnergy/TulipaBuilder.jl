@testsnippet CreateConnectionSetup begin
    const MIN_ASSET_TABLES = ["asset", "asset_both", "asset_commission", "asset_milestone"]
    const MIN_FLOW_TABLES = ["flow", "flow_commission", "flow_milestone"]
end

@testitem "create_connection throws ArgumentError for missing required schema tables" tags =
    [:schema, :unit, :fast] setup = [CommonSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Schema missing all required tables
    @test_throws ArgumentError create_connection(tulipa, Dict{String,Any}())

    # Schema missing one required table
    incomplete_schema = copy(TestSchema.schema)
    delete!(incomplete_schema, "asset_both")
    @test_throws ArgumentError create_connection(tulipa, incomplete_schema)

    # Error message lists the missing table
    err = try
        create_connection(tulipa, incomplete_schema)
    catch e
        e
    end
    @test occursin("asset_both", err.msg)
end

@testitem "Create connection after add_asset" tags = [:schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == ["asset"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer, capacity = 1.0)
    add_or_update_year!(tulipa, 2030, length = 24, is_milestone = true)
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == MIN_ASSET_TABLES
end

@testitem "Create connection after add_flow" tags = [:schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == ["asset", "flow"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    add_or_update_year!(tulipa, 2030, length = 24, is_milestone = true)
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == [MIN_ASSET_TABLES; MIN_FLOW_TABLES]
end

@testitem "Create connection after attach_profile" tags = [:schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; "assets_profiles"; "profiles"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; "assets_profiles"; MIN_FLOW_TABLES; "profiles"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; MIN_FLOW_TABLES; "flows_profiles"; "profiles"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == [
        MIN_ASSET_TABLES
        "assets_profiles"
        MIN_FLOW_TABLES
        "flows_profiles"
        "profiles"
    ]
end

@testitem "Create connection after attach_timeframe_profile!" tags = [:schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "storage", :storage)
    attach_profile!(tulipa, "storage", :availability, 2030, ones(24))
    attach_timeframe_profile!(tulipa, "storage", :max_storage_level, 2030, ones(10))
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == [
        MIN_ASSET_TABLES
        "assets_profiles"
        "assets_timeframe_profiles"
        "profiles"
        "profiles_timeframe"
    ]
end

@testitem "Create connection after add_asset_group" tags = [:schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset_group!(tulipa, "group", 2030, invest_method = "use_only_investment_units")
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == ["investment_group_asset"]
end

@testitem "Asset group limits and members map to investment group tables" tags =
    [:schema, :unit, :fast] setup = [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "solar", :producer, capacity = 100.0, investment_group = "res_max")
    add_asset!(tulipa, "wind", :producer, capacity = 3.0, investment_group = "res_max")
    add_asset!(tulipa, "ccgt", :producer, investment_group = "ccgt_min")
    add_asset!(tulipa, "other", :producer, capacity = 7.0)
    add_asset_group!(
        tulipa,
        "res_max",
        2030,
        invest_method = "use_only_investment_units",
        max_investment_limit = 40,
    )
    add_asset_group!(
        tulipa,
        "ccgt_min",
        2030,
        invest_method = "use_only_investment_units",
        min_investment_limit = 10,
    )
    connection = create_connection(tulipa, TestSchema.schema)

    groups =
        DataFrame(DuckDB.query(connection, "FROM investment_group_asset ORDER BY name"))
    @test groups.name == ["ccgt_min", "res_max"]
    @test groups.milestone_year == [2030, 2030]
    @test groups.invest_method == fill("use_only_investment_units", 2)
    @test groups.constraint_sense == [">=", "<="]
    @test groups.rhs == [10.0, 40.0]

    members = DataFrame(
        DuckDB.query(
            connection,
            "FROM investment_group_asset_membership ORDER BY group_name, asset",
        ),
    )
    @test members.group_name == ["ccgt_min", "res_max", "res_max"]
    @test members.asset == ["ccgt", "solar", "wind"]
    @test members.milestone_year == [2030, 2030, 2030]
    # Coefficient is the asset capacity, or the schema default when not set
    @test members.coefficient == [0.0, 100.0, 3.0]
end

@testitem "Asset group with both min and max limits throws" tags = [:schema, :unit, :fast] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "solar", :producer, capacity = 100.0, investment_group = "res")
    add_asset_group!(
        tulipa,
        "res",
        2030,
        min_investment_limit = 10,
        max_investment_limit = 40,
    )
    @test_throws ArgumentError create_connection(tulipa, TestSchema.schema)
end

@testitem "Create connection after set_partition!" tags = [:schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    set_partition!(tulipa, "producer", 2030, 1, 3)
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) == ["asset", "assets_rep_periods_partitions"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    set_partition!(tulipa, "producer", "consumer", 2030, 1, 3)
    connection = create_connection(tulipa, TestSchema.schema)
    @test get_non_empty_tables(connection) ==
          ["asset", "flow", "flows_rep_periods_partitions"]
end
