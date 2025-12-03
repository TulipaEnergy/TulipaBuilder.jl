@testitem "Comparison of Tiny generated via TulipaBuilder" tags = [:integration] setup =
    [CommonSetup] begin
    tulipa = TulipaData{String}()

    ### assets
    add_asset!(
        tulipa,
        "ccgt",
        :producer,
        capacity = 400.0,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        investment_cost = 3.0,
    )
    add_asset!(tulipa, "demand", :consumer, peak_demand = 30.0)
    add_asset!(tulipa, "ens", :producer, capacity = 1115.0)
    add_asset!(
        tulipa,
        "ocgt",
        :producer,
        capacity = 100.0,
        investment_method = "simple",
        investable = true,
        investment_cost = 4.0,
    )
    add_asset!(
        tulipa,
        "solar",
        :producer,
        description = "Solar",
        capacity = 10.0,
        resolution = 6,
        initial_units = 10,
        investment_method = "simple",
        investable = true,
        investment_cost = 4.0,
    )
    add_asset!(
        tulipa,
        "wind",
        :producer,
        capacity = 50.0,
        investment_method = "simple",
        investable = true,
        investment_cost = 4.0,
    )

    ### flow
    add_flow!(tulipa, "solar", "demand")
    for asset in ("ccgt", "ocgt")
        add_flow!(tulipa, asset, "demand")
    end

    ### profiles

    xls = XLSX.readtable(joinpath(@__DIR__, "tulipatest.xlsx"), "profiles")
    df = DataFrame(xls)

    attach_profile!(tulipa, "solar", :availability, 2030, df[!, "Solar"])
    attach_profile!(tulipa, "demand", :demand, 2030, df[!, "Demand"])
    attach_profile!(tulipa, "ccgt", :availability, 2030, 0.5 .+ 0.1 * randn(24))
    # no profile for ocgt

    connection = create_connection(tulipa)

    # External
    period_duration = 24
    num_rep_periods = 3
    TC.cluster!(connection, period_duration, num_rep_periods)
    TEM.populate_with_defaults!(connection)

    # Comparison
    tiny_folder = joinpath(pkgdir(TEM), "test", "inputs", "Tiny")
    for file in readdir(tiny_folder, join = true)
        table_name = replace(splitext(basename(file))[1], "-" => "_")
        DuckDB.query(
            connection,
            "CREATE TABLE expected_$table_name AS FROM read_csv('$file')",
        )

        @info table_name
        @testset "Comparing $table_name" begin
            compare_duckdb_tables(connection, table_name, "expected_$table_name")
        end
    end
end
