@testsnippet CreateConnectionSetup begin
    const MIN_ASSET_TABLES = ["asset", "asset_both", "asset_commission", "asset_milestone"]
    const MIN_FLOW_TABLES = ["flow", "flow_commission", "flow_milestone"]
end

@testitem "Create connection after add_asset" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) == ["asset"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer, capacity = 1.0)
    add_or_update_year!(tulipa, 2030, length = 24)
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) == [MIN_ASSET_TABLES; "year_data"]
end

@testitem "Create connection after add_flow" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) == ["asset", "flow"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    add_or_update_year!(tulipa, 2030, length = 24)
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; MIN_FLOW_TABLES; "year_data"]
end

@testitem "Create connection after attach_profile" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; "assets_profiles"; "profiles"; "year_data"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; "assets_profiles"; MIN_FLOW_TABLES; "profiles"; "year_data"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) ==
          [MIN_ASSET_TABLES; MIN_FLOW_TABLES; "flows_profiles"; "profiles"; "year_data"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) == [
        MIN_ASSET_TABLES
        "assets_profiles"
        MIN_FLOW_TABLES
        "flows_profiles"
        "profiles"
        "year_data"
    ]
end

@testitem "Create connection after add_asset_group" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    tulipa = TulipaData()
    add_asset_group!(tulipa, "group", 2030, invest_method = true)
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) == ["group_asset"]
end

@testitem "Create connection after set_partition!" tags = [] setup =
    [CommonSetup, CreateConnectionSetup] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    set_partition!(tulipa, "producer", 2030, 1, 3)
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) == ["asset", "assets_rep_periods_partitions"]

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    set_partition!(tulipa, "producer", "consumer", 2030, 1, 3)
    connection = create_connection(tulipa)
    @test get_non_empty_tables(connection) ==
          ["asset", "flow", "flows_rep_periods_partitions"]
end
