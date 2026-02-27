@testsnippet TinyFixes begin
    # These are "default" for Tiny, but not the default when populating with defaults
    # TODO: Open discussion in TEM on whether these should be kept or not
    asset_extra_defaults = (
        # asset_commission
        fixed_cost_storage_energy = 5.0,    # default is 0.0
        initial_storage_level = 0.0,        # default is null
        # asset
        technical_lifetime = 15,            # default is 1
        discount_rate = 0.05,               # default is 0.0
    )
    flow_extra_defaults = (
        # flow
        technical_lifetime = 10,            # default is 1
        discount_rate = 0.02,               # default is 0.0
        carrier = "electricity",            # default is null
    )

    # Most of these are `missing` in the expected tables, so populate_with_defaults will
    # correct them even if the column exists in the DB
    unfixable_missing_columns = Dict(
        "asset" => ["min_operating_point", "max_ramp_down", "max_ramp_up"],
        "assets_profiles" => ["profile_name"],
    )
end

@testitem "Comparison of Tiny generated via TulipaBuilder" tags = [:integration] setup =
    [CommonSetup, TinyFixes] begin

    tulipa = TulipaData{String}()

    ### assets
    add_asset!(
        tulipa,
        "ccgt",
        :producer;
        capacity = 400.0,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        investment_cost = 40.0,
        investment_limit = 10000.0,
        asset_extra_defaults...,
    )
    add_asset!(tulipa, "demand", :consumer; peak_demand = 1115.0, asset_extra_defaults...)
    add_asset!(
        tulipa,
        "ens",
        :producer;
        capacity = 1115.0,
        initial_units = 1.0,
        asset_extra_defaults...,
    )
    add_asset!(
        tulipa,
        "ocgt",
        :producer;
        capacity = 100.0,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        investment_cost = 25.0,
        asset_extra_defaults...,
    )
    add_asset!(
        tulipa,
        "solar",
        :producer;
        description = "Solar",
        capacity = 10.0,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        investment_cost = 50.0,
        asset_extra_defaults...,
    )
    add_asset!(
        tulipa,
        "wind",
        :producer;
        capacity = 50.0,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        investment_cost = 70.0,
        asset_extra_defaults...,
    )

    ### flow
    add_flow!(tulipa, "ccgt", "demand", operational_cost = 0.05, ; flow_extra_defaults...)
    add_flow!(tulipa, "ens", "demand", operational_cost = 0.18, ; flow_extra_defaults...)
    add_flow!(tulipa, "ocgt", "demand", operational_cost = 0.07, ; flow_extra_defaults...)
    add_flow!(tulipa, "solar", "demand", ; flow_extra_defaults...)
    add_flow!(tulipa, "wind", "demand", operational_cost = 0.001, ; flow_extra_defaults...)

    ### profiles

    tiny_profiles_path = joinpath(@__DIR__, "..", "test", "tiny-profiles.csv")
    df = DataFrame(CSV.File(tiny_profiles_path))

    attach_profile!(tulipa, "solar", :availability, 2030, df[!, "availability-solar"])
    attach_profile!(tulipa, "demand", :demand, 2030, df[!, "demand-demand"])
    attach_profile!(tulipa, "wind", :availability, 2030, df[!, "availability-wind"])
    # no profile for ocgt

    connection = create_connection(tulipa)

    # External
    period_duration = 24
    num_rep_periods = 3
    TC.cluster!(
        connection,
        period_duration,
        num_rep_periods;
        layout = TC.ProfilesTableLayout(year = :milestone_year),
    )
    TEM.populate_with_defaults!(connection)

    # Comparison
    tiny_folder = joinpath(pkgdir(TEM), "test", "inputs", "Tiny")
    for file in readdir(tiny_folder, join = true)
        table_name = replace(splitext(basename(file))[1], "-" => "_")
        # TODO: Try to make clustering more predictable to compare these tables as well
        if table_name in ["rep_periods_mapping", "profiles_rep_periods"]
            continue
        end
        DuckDB.query(
            connection,
            "CREATE TABLE expected_$table_name AS FROM read_csv('$file')",
        )
        num_rows = only([
            row.row_count for row in DuckDB.query(
                connection,
                "SELECT COUNT(*) AS row_count FROM expected_$table_name",
            )
        ])
        if num_rows == 0
            # Ignore empty tables
            continue
        end

        @testset "Comparing $table_name" begin
            compare_duckdb_tables(connection, table_name, "expected_$table_name")
        end
    end
end
