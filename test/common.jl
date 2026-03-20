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

    function get_non_empty_tables(connection)
        return sort(
            get_vector_from_duckdb_query(
                connection,
                "SELECT table_name FROM duckdb_tables() WHERE estimated_size > 0",
            ),
        )
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
        actual_cols = Set(column_names["actual"])
        expected_cols = Set(column_names["expected"])
        if actual_cols != expected_cols
            @error "[compare_duckdb_tables] Column mismatch" table = actual_table_name missing_in_actual =
                sort(collect(setdiff(expected_cols, actual_cols))) extra_in_actual =
                sort(collect(setdiff(actual_cols, expected_cols)))
        end
        @test actual_cols == expected_cols

        # Tables have the same amount of rows
        num_rows = Dict(
            key => get_vector_from_duckdb_query(
                connection,
                "SELECT COUNT(*) FROM $table_name",
            )[1] for (key, table_name) in table_names
        )
        if num_rows["actual"] != num_rows["expected"]
            @error "[compare_duckdb_tables] Row count mismatch" table = actual_table_name actual =
                num_rows["actual"] expected = num_rows["expected"]
        end
        @test num_rows["actual"] == num_rows["expected"]

        # Tables have the same content
        missing_columns = get(unfixable_missing_columns, actual_table_name, String[])
        distinct_union_select =
            isempty(missing_columns) ? "*" :
            "* EXCLUDE (" * join(missing_columns, ", ") * ")"
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
        if size(distinct_union_df, 1) != num_rows["actual"]
            columns_without_default = [
                key for (key, value) in TEM.schema[actual_table_name] if
                !haskey(value, "default")
            ]
            primary_keys = columns_without_default ∩ POSSIBLE_PRIMARY_KEYS
            select_cols =
                join([c for c in sort(column_names["actual"]) if c ∉ missing_columns], ", ")
            only_in_actual_df = DataFrame(
                DuckDB.query(
                    connection,
                    "SELECT $select_cols FROM $actual_table_name
                     EXCEPT
                     SELECT $select_cols FROM $expected_table_name",
                ),
            )
            only_in_expected_df = DataFrame(
                DuckDB.query(
                    connection,
                    "SELECT $select_cols FROM $expected_table_name
                     EXCEPT
                     SELECT $select_cols FROM $actual_table_name",
                ),
            )
            @error "[compare_duckdb_tables] Content mismatch" table = actual_table_name primary_keys =
                primary_keys only_in_actual =
                sprint(show, only_in_actual_df; context = :displaysize => (1000, 1000)) only_in_expected =
                sprint(show, only_in_expected_df; context = :displaysize => (1000, 1000))
        end
        @test size(distinct_union_df, 1) == num_rows["actual"]
    end
end
