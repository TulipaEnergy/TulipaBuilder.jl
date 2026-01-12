export create_connection

"""
    create_empty_table_from_schema!(connection, table_name, schema, columns)

Create an empty table with name `table_name`, overwritting an existing table,
if necessary. The table should have the columns specified in `columns`, and
their type and default values are informed by the `schema`.
The `schema` is expected to be from TulipaEnergyModel for a given table.

This function is for internal use only.
"""
function create_empty_table_from_schema!(connection, table_name, schema, columns)
    query = "CREATE OR REPLACE TABLE $table_name ("
    for (col_name, props) in schema
        if !(col_name in columns)
            continue
        end
        col_type = props["type"]
        query *= "\"$col_name\" $col_type"

        col_default = get(props, "default", "NULL")
        if col_default != "NULL"
            col_default = TIO.FmtSQL.fmt_quote(col_default)
            query *= " DEFAULT $col_default"
        end
        query *= ", "
    end
    query *= ")"
    DuckDB.query(connection, query)

    return connection
end

"""
    _get_select_query_row(key, value, table_name)

Using the TulipaEnergyModel.schema for `table_name`,
"""
function _get_select_query_row(key, value, table_name)
    key = String(key)
    if !haskey(TEM.schema[table_name], key)
        return ""
    end
    col_type = TEM.schema[table_name][key]["type"]
    col_value = TIO.FmtSQL.fmt_quote(value)
    return "$col_value::$col_type AS \"$key\", "
end

"""
    propagate_year_data!(tulipa_data)

Propagates keys from `asset` to `asset_milestone`, `asset_commission` and `asset_both`, to avoid explicitly attaching a global value.
"""
function propagate_year_data!(tulipa)
    # Propagate from asset to asset_milestone and asset_commission
    years = keys(tulipa.years)
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset = tulipa.graph[asset_name]

        for (table_name, attach!) in (
            ("asset_milestone", attach_milestone_data!),
            ("asset_commission", attach_commission_data!),
        )
            relevant_keys = Dict(
                key => value for (key, value) in asset.basic_data if
                haskey(TEM.schema[table_name], string(key))
            )
            for year in years
                attach!(asset, year; on_conflict = :skip, relevant_keys...)
            end
        end
    end

    # Propagate from asset to asset_both
    # TODO: This is limited to milestone_year=commission_year because otherwise I have no idea what to do
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset = tulipa.graph[asset_name]

        relevant_keys = Dict(
            key => value for (key, value) in asset.basic_data if
            haskey(TEM.schema["asset_both"], string(key))
        )
        for year in years
            attach_both_years_data!(
                asset,
                year,
                year;
                on_conflict = :skip,
                relevant_keys...,
            )
        end
    end

    # Propagate from flow to flow_commission and flow_milestone
    for (from_asset_name, to_asset_name) in MetaGraphsNext.edge_labels(tulipa.graph)
        flow = tulipa.graph[from_asset_name, to_asset_name]

        for (table_name, attach!) in (
            ("flow_milestone", attach_milestone_data!),
            ("flow_commission", attach_commission_data!),
        )
            relevant_keys = Dict(
                key => value for (key, value) in flow.basic_data if
                haskey(TEM.schema[table_name], string(key))
            )
            for year in years
                attach!(flow, year; on_conflict = :skip, relevant_keys...)
            end
        end
    end

    # Propagate from flow to flow_both
    # TODO: Not all flows are added to flow_both, so we need to filter. Skipping for now
    # for (from_asset_name, to_asset_name) in MetaGraphsNext.edge_labels(tulipa.graph)
    #     flow = tulipa.graph[from_asset_name, to_asset_name]

    #     relevant_keys = Dict(
    #         key => value for (key, value) in flow.basic_data if
    #         haskey(TEM.schema["flow_both"], string(key))
    #     )
    #     for year in years
    #         attach_both_years_data!(flow, year, year; on_conflict = :skip, relevant_keys...)
    #     end
    # end
end

# IDEA: function for_each_asset(f, tulipa)

"""
    create_connection(tulipa_data)
    create_connection(tulipa_data, db)

Creates a DuckDB connection and populates it with the data from `tulipa_data`.
If `db` is not given, a memory connection is created.
"""
function create_connection(tulipa::TulipaData, db = ":memory:")
    connection = DBInterface.connect(DuckDB.DB, db)
    run_query(s) = DuckDB.query(connection, s)

    function collect_sub_keys(d::Dict{<:Any,Dict{Symbol,Any}})
        if length(d) == 0
            return String[]
        end

        return union(keys.(values(d))...)
    end

    # Propagate yearly information before continuing
    propagate_year_data!(tulipa)

    # Table asset
    # TODO: This is a terrible way of doing this
    columns = [
        "asset"
        "type"
        unique([
            string(key) for asset_name in MetaGraphsNext.labels(tulipa.graph) for
            (key, value) in tulipa.graph[asset_name].basic_data
        ])
    ]
    create_empty_table_from_schema!(connection, "asset", TEM.schema["asset"], columns)
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset_type = tulipa.graph[asset_name].type
        query = "INSERT INTO asset BY NAME (SELECT '$asset_name' AS asset, '$asset_type' AS type, "
        asset = tulipa.graph[asset_name]
        for (key, value) in asset.basic_data
            query_row = _get_select_query_row(key, value, "asset")
            if query_row == ""
                @debug "Ignoring column $key from asset '$asset_name'"
                continue
            end
            query *= query_row
        end
        query *= ")"
        run_query(query)
    end

    # Table asset_both
    columns = [
        "asset"
        "commission_year"
        "milestone_year"
        unique([
            string(key) for asset_name in MetaGraphsNext.labels(tulipa.graph) for
            key in collect_sub_keys(tulipa.graph[asset_name].both_years_data)
        ])
    ]
    create_empty_table_from_schema!(
        connection,
        "asset_both",
        TEM.schema["asset_both"],
        columns,
    )
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset = tulipa.graph[asset_name]
        for ((commission_year, milestone_year), values) in asset.both_years_data
            query = """INSERT INTO asset_both BY NAME (
                SELECT '$asset_name' AS asset,
                    $milestone_year AS milestone_year,
                    $commission_year AS commission_year,
            """
            for (key, value) in values
                query_row = _get_select_query_row(key, value, "asset_both")
                if query_row == ""
                    @debug "Ignoring column $key from asset '$asset_name' (both years)"
                    continue
                end
                query *= query_row
            end
            query *= ")"
            run_query(query)
        end
    end

    # Table asset_commission
    columns = [
        "asset"
        "commission_year"
        unique([
            string(key) for asset_name in MetaGraphsNext.labels(tulipa.graph) for
            key in collect_sub_keys(tulipa.graph[asset_name].commission_year_data)
        ])
    ]
    create_empty_table_from_schema!(
        connection,
        "asset_commission",
        TEM.schema["asset_commission"],
        columns,
    )
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset = tulipa.graph[asset_name]
        for (commission_year, values) in asset.commission_year_data
            query = """INSERT INTO asset_commission BY NAME (
                SELECT '$asset_name' AS asset,
                $commission_year AS commission_year,
            """
            for (key, value) in values
                query_row = _get_select_query_row(key, value, "asset_commission")
                if query_row == ""
                    @debug "Ignoring column $key from asset '$asset_name' (commission year)"
                    continue
                end
                query *= query_row
            end
            query *= ")"
            run_query(query)

        end
    end

    # Table asset_milestone
    columns = [
        "asset"
        "milestone_year"
        unique([
            string(key) for asset_name in MetaGraphsNext.labels(tulipa.graph) for
            key in collect_sub_keys(tulipa.graph[asset_name].milestone_year_data)
        ])
    ]
    create_empty_table_from_schema!(
        connection,
        "asset_milestone",
        TEM.schema["asset_milestone"],
        columns,
    )
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset = tulipa.graph[asset_name]
        for (milestone_year, values) in asset.milestone_year_data
            query = """INSERT INTO asset_milestone BY NAME (
                SELECT '$asset_name' AS asset,
                $milestone_year AS milestone_year,
            """
            for (key, value) in values
                query_row = _get_select_query_row(key, value, "asset_milestone")
                if query_row == ""
                    @debug "Ignoring column $key from asset '$asset_name' (milestone year)"
                    continue
                end
                query *= query_row
            end
            query *= ")"
            run_query(query)
        end
    end

    # Table flow
    columns = [
        "from_asset"
        "to_asset"
        unique([
            string(key) for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph) for
            (key, value) in tulipa.graph[flow_tuple...].basic_data
        ])
    ]
    create_empty_table_from_schema!(connection, "flow", TEM.schema["flow"], columns)
    for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph)
        flow = tulipa.graph[flow_tuple...]
        from_asset = flow_tuple[1]
        to_asset = flow_tuple[2]
        query = """INSERT INTO flow BY NAME (
            SELECT '$from_asset' AS from_asset,
            '$to_asset' AS to_asset,
        """
        for (key, value) in flow.basic_data
            query_row = _get_select_query_row(key, value, "flow")
            if query_row == ""
                @debug "Ignoring column $key from flow ('$from_asset','$to_asset')"
                continue
            end
            query *= query_row
        end
        query *= ")"
        run_query(query)
    end

    # Table flow_both
    columns = [
        "from_asset"
        "to_asset"
        "commission_year"
        "milestone_year"
        unique([
            string(key) for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph) for
            key in collect_sub_keys(tulipa.graph[flow_tuple...].both_years_data)
        ])
    ]
    create_empty_table_from_schema!(
        connection,
        "flow_both",
        TEM.schema["flow_both"],
        columns,
    )
    for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph)
        from_asset = flow_tuple[1]
        to_asset = flow_tuple[2]
        flow = tulipa.graph[flow_tuple...]
        for ((commission_year, milestone_year), values) in flow.both_years_data
            query = """INSERT INTO flow_both BY NAME (
                SELECT '$from_asset' AS from_asset,
                    '$to_asset' AS to_asset,
                    $milestone_year AS milestone_year,
                    $commission_year AS commission_year,
            """
            for (key, value) in values
                query_row = _get_select_query_row(key, value, "flow_both")
                if query_row == ""
                    @debug "Ignoring column $key from flow ('$from_asset','$to_asset') (both years)"
                    continue
                end
                query *= query_row
            end
            query *= ")"
            run_query(query)
        end
    end

    # Table flow_commission
    columns = [
        "from_asset"
        "to_asset"
        "commission_year"
        unique([
            string(key) for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph) for
            key in collect_sub_keys(tulipa.graph[flow_tuple...].commission_year_data)
        ])
    ]
    create_empty_table_from_schema!(
        connection,
        "flow_commission",
        TEM.schema["flow_commission"],
        columns,
    )
    for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph)
        from_asset = flow_tuple[1]
        to_asset = flow_tuple[2]
        flow = tulipa.graph[flow_tuple...]
        for (commission_year, values) in flow.commission_year_data
            query = """INSERT INTO flow_commission BY NAME (
                SELECT '$from_asset' AS from_asset,
                    '$to_asset' AS to_asset,
                    $commission_year AS commission_year,
            """
            for (key, value) in values
                query_row = _get_select_query_row(key, value, "flow_commission")
                if query_row == ""
                    @debug "Ignoring column $key from flow ('$from_asset','$to_asset') (commission years)"
                    continue
                end
                query *= query_row
            end
            query *= ")"
            run_query(query)
        end
    end

    # Table flow_milestone
    columns = [
        "from_asset"
        "to_asset"
        "milestone_year"
        unique([
            string(key) for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph) for
            key in collect_sub_keys(tulipa.graph[flow_tuple...].milestone_year_data)
        ])
    ]
    create_empty_table_from_schema!(
        connection,
        "flow_milestone",
        TEM.schema["flow_milestone"],
        columns,
    )
    for flow_tuple in MetaGraphsNext.edge_labels(tulipa.graph)
        from_asset = flow_tuple[1]
        to_asset = flow_tuple[2]
        flow = tulipa.graph[flow_tuple...]
        for (milestone_year, values) in flow.milestone_year_data
            query = """INSERT INTO flow_milestone BY NAME (
                SELECT '$from_asset' AS from_asset,
                    '$to_asset' AS to_asset,
                    $milestone_year AS milestone_year,
            """
            for (key, value) in values
                query_row = _get_select_query_row(key, value, "flow_milestone")
                if query_row == ""
                    @debug "Ignoring column $key from flow ('$from_asset','$to_asset') (milestone years)"
                    continue
                end
                query *= query_row
            end
            query *= ")"
            run_query(query)
        end
    end

    # Table profiles
    DuckDB.query(
        connection,
        "CREATE OR REPLACE TABLE profiles (
            profile_name VARCHAR,
            year INT64,
            timestep INT64,
            value DOUBLE,
        )",
    )
    # Table asset_profiles
    DuckDB.query(
        connection,
        "CREATE OR REPLACE TABLE assets_profiles (
            asset VARCHAR,
            commission_year INT64,
            profile_name VARCHAR,
            profile_type VARCHAR,
        )",
    )
    for asset_name in MetaGraphsNext.labels(tulipa.graph)
        asset = tulipa.graph[asset_name]
        for ((profile_type, year), profile_value) in asset.profiles
            profile_name = "$asset_name-$profile_type-$year"
            profiles_df = DataFrame(
                profile_name = profile_name,
                year = year,
                timestep = 1:length(profile_value),
                value = profile_value,
            )
            DuckDB.register_data_frame(connection, profiles_df, "tmp_profile")
            DuckDB.query(
                connection,
                "INSERT INTO profiles BY NAME (SELECT * FROM tmp_profile)",
            )
            DuckDB.query(connection, "DROP VIEW tmp_profile")

            DuckDB.query(
                connection,
                "INSERT INTO assets_profiles BY NAME (SELECT
                    '$asset_name' AS asset,
                    $year AS commission_year,
                    '$profile_name' AS profile_name,
                    '$profile_type' AS profile_type,
                )",
            )
        end
    end

    DuckDB.query(
        connection,
        "CREATE OR REPLACE TABLE year_data (
            year INT64,
            length INT64,
            is_milestone BOOLEAN,
        )",
    )
    for (year, props) in tulipa.years
        if !haskey(props, :length)
            error("Not possible to determine length of year $year. Try attaching a profile")
        end
        is_milestone = get(props, :is_milestone, false)
        year_length = props[:length]
        DuckDB.query(
            connection,
            "INSERT INTO year_data VALUES ($year, $year_length, $is_milestone)",
        )
    end

    # Complement the *-milestone and *-commission tables with missing *,year combinations
    # TODO :Evaluate CREATE OR REPLACE alternative
    for t_prefix in (:asset, :flow), t_suffix in (:commission, :milestone)
        table_name = "$(t_prefix)_$(t_suffix)"
        year_col = "$(t_suffix)_year"
        main_cols = t_prefix == :asset ? [:asset] : [:from_asset, :to_asset]
        where_is_milestone = t_suffix == :milestone ? "WHERE is_milestone" : ""

        cte_all_cols = join(("$t_prefix.$col" for col in main_cols), ", ")
        cte_all = "SELECT $cte_all_cols, year_data.year
            FROM $t_prefix CROSS JOIN year_data $where_is_milestone"

        cte_rem_cols = join(("cte_all.$col" for col in main_cols), ", ")
        cte_rem_join =
            join(("cte_all.$col = $table_name.$col" for col in main_cols), " AND ")
        cte_rem = "SELECT $cte_rem_cols, cte_all.year AS $year_col
            FROM cte_all ANTI JOIN $table_name
            ON $cte_rem_join AND cte_all.year = $table_name.$year_col"

        DuckDB.query(
            connection,
            "INSERT INTO $table_name BY NAME (
                WITH cte_all AS ($cte_all),
                    cte_remaining_rows AS (
                    $cte_rem
                )
                SELECT * FROM cte_remaining_rows
            )
            ",
        )
    end

    # Complement the asset_both tables with rows from asset_milestone
    ## Only check for 'compact' if the investment_method column exists
    has_investment_method_column = any(
        haskey(tulipa.graph[asset_name].basic_data, :investment_method) for
        asset_name in MetaGraphsNext.labels(tulipa.graph)
    )
    where_investment_method = if has_investment_method_column
        "WHERE asset.investment_method != 'compact'"
    else
        ""
    end
    ## SQL
    DuckDB.query(
        connection,
        "INSERT INTO asset_both BY NAME (
            SELECT
                asset.asset,
                asset_milestone.milestone_year,
                asset_milestone.milestone_year as commission_year
            FROM asset_milestone
            JOIN asset ON asset_milestone.asset = asset.asset
            ANTI JOIN asset_both
                ON asset_both.asset = asset_milestone.asset
                AND asset_both.milestone_year = asset_milestone.milestone_year
            $where_investment_method
        )
        ",
    )

    # group_asset tables
    if length(tulipa.asset_groups) > 0
        create_empty_table_from_schema!(
            connection,
            "group_asset",
            TEM.schema["group_asset"],
            [
                "name",
                "milestone_year",
                "invest_method",
                "min_investment_limit",
                "max_investment_limit",
            ],
        )
        for ((group_name, year), group_data) in tulipa.asset_groups
            query = """INSERT INTO group_asset BY NAME (
                SELECT '$group_name' AS name, $year AS milestone_year,"""
            for (key, value) in group_data
                query *= _get_select_query_row(key, value, "group_asset")
            end
            query *= ")"
            run_query(query)
        end
    end

    return connection
end
