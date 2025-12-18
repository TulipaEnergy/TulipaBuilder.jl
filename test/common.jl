@testsnippet CommonSetup begin
    using CSV: CSV
    using DataFrames: DataFrame
    using DuckDB: DuckDB
    using JuMP: JuMP
    using TulipaClustering: TulipaClustering as TC
    using TulipaEnergyModel: TulipaEnergyModel as TEM
    using XLSX: XLSX

    # TODO: Manually defined list of possible primary keys.
    # When TulipaEnergyModel defines these explicitly, this should be unnecessary
    POSSIBLE_PRIMARY_KEYS = [
        "from_asset",
        "to_asset",
        "asset",
        "year",
        "commission_year",
        "milestone_year",
        "name",
        "profile_name",
        "profile_type",
        "period",
        "timestep",
        "scenario",
        "rep_period",
    ]

    function get_vector_from_duckdb_query(connection, query)
        return [row[1] for row in DuckDB.query(connection, query)]
    end

    function compare_duckdb_tables(connection, actual_table_name, expected_table_name)
        table_names = Dict("actual" => actual_table_name, "expected" => expected_table_name)

        # Tables have the same column names
        column_names = Dict(
            key => get_vector_from_duckdb_query(
                connection,
                "SELECT column_name FROM duckdb_columns() WHERE table_name = '$table_name'",
            ) for (key, table_name) in table_names
        )
        @test Set(column_names["actual"]) == Set(column_names["expected"])

        # Tables have the same amount of rows
        num_rows = Dict(
            key => get_vector_from_duckdb_query(
                connection,
                "SELECT COUNT(*) FROM $table_name",
            )[1] for (key, table_name) in table_names
        )
        @test num_rows["actual"] == num_rows["expected"]

        # Tables have the same content
        distinct_union_select = "*"
        missing_columns = get(unfixable_missing_columns, actual_table_name, String[])
        if haskey(unfixable_missing_columns, actual_table_name)
            distinct_union_select = "* EXCLUDE (" * join(missing_columns, ",") * ")"
        end
        distinct_union_df = DataFrame(
            DuckDB.query(
                connection,
                "WITH cte_union AS (
                    FROM $actual_table_name
                    UNION BY NAME
                    FROM $expected_table_name
                )
                SELECT DISTINCT $distinct_union_select FROM cte_union
                ",
            ),
        )
        @test size(distinct_union_df, 1) == num_rows["actual"]

        # DEBUGGING (hopefully won't need again)
        # if size(distinct_union_df, 1) != num_rows["actual"]
        #     columns_without_default = [
        #         key for (key, value) in TEM.schema[actual_table_name] if
        #         !haskey(value, "default")
        #     ]
        #     primary_keys = columns_without_default ∩ POSSIBLE_PRIMARY_KEYS
        #     sort!(distinct_union_df, primary_keys)
        #     @info "DEBUGGING" distinct_union_df
        #     @info "DEBUGGING" primary_keys
        #     primary_values = unique(sort(distinct_union_df[:, primary_keys], primary_keys))
        #     # if size(primary_values, 1) != num_rows["actual"]
        #     @info "DEBUGGING" primary_values
        #     # end
        #     for column in column_names["actual"]
        #         if column in primary_keys || column in missing_columns
        #             continue
        #         end
        #         df = unique(sort(distinct_union_df[:, [primary_keys; column]]))
        #         if size(df, 1) != num_rows["actual"]
        #             @info "DEBUGGING" df
        #         end
        #     end
        # end
    end
end
