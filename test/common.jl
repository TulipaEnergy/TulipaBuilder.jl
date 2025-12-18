@testsnippet CommonSetup begin
    using CSV: CSV
    using DataFrames: DataFrame
    using DuckDB: DuckDB
    using JuMP: JuMP
    using TulipaClustering: TulipaClustering as TC
    using TulipaEnergyModel: TulipaEnergyModel as TEM
    using XLSX: XLSX

    function get_vector_from_duckdb_query(connection, query)
        return [row[1] for row in DuckDB.query(connection, query)]
    end

    function compare_duckdb_tables(connection, actual_table_name, expected_table_name)
        table_names = Dict("actual" => actual_table_name, "expected" => expected_table_name)
        column_names = Dict(
            key => get_vector_from_duckdb_query(
                connection,
                "SELECT column_name FROM duckdb_columns() WHERE table_name = '$table_name'",
            ) for (key, table_name) in table_names
        )
        # Tables have the same column names
        @test Set(column_names["actual"]) == Set(column_names["expected"])

        num_rows = Dict(
            key => get_vector_from_duckdb_query(
                connection,
                "SELECT COUNT(*) FROM $table_name",
            )[1] for (key, table_name) in table_names
        )
        # Tables have the same amount of rows
        @test num_rows["actual"] == num_rows["expected"]

        # Tables have the same content
        get_vector_from_duckdb_query(
            connection,
            "WITH cte_a_minus_b AS (
                SELECT
                FROM $actual_table_name
                ANTI JOIN $expected_table_name
            )",
        )
    end
end
