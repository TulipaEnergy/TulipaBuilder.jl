export create_case_study_csv_folder

"""
    create_case_study_csv_folder(connection, case_study_folder; overwrite = true)

Creates the CSV files that correspond to the Tulipa input tables in
`connection` and saves them in the `case_study_folder`.
If `overwrite`, then the files are overwritten if they exist.

The tables that are exported are the ones that are defined in `TulipaEnergyModel.schema`, and the `profiles` table.
"""
function create_case_study_csv_folder(connection, case_study_folder; overwrite = true)
    # Check if folder exists and handle overwrite logic
    if isdir(case_study_folder)
        if !overwrite && !isempty(readdir(case_study_folder))
            error("Directory $case_study_folder is not empty and overwrite=false")
        end
    else
        mkpath(case_study_folder)
    end


    existing_tables_in_connection =
        [row.table_name::String for row in DuckDB.query(connection, "FROM duckdb_tables")]

    # For every table in TEM.schema (keys of the dict),
    # export the table to CSV using DuckDB.query(connection, ...)
    for table_name in keys(TEM.schema) ∪ ["profiles"] # profiles is explicitly here since TEM doesn't include it (not sure what TODO about it)
        if !(table_name in existing_tables_in_connection)
            @debug "No table '$table_name' in the connection. Skipping"
            continue
        end
        csv_path = joinpath(case_study_folder, "$table_name.csv")
        query = "COPY $table_name TO '$csv_path' (HEADER, DELIMITER ',')"
        DuckDB.query(connection, query)
    end

    return case_study_folder
end
