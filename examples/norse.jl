#=
    Example: Norse data from TulipaEnergyModel (no defaults, no clustering)

    Manually recreate the Norse data from TulipaEnergyModel, without populating with defaults

    Running:

        julia --project=examples examples/norse.jl
=#

using TulipaBuilder:
    TulipaData,
    add_asset!,
    add_flow!,
    attach_profile!,
    create_connection,
    create_case_study_csv_folder
using CSV: CSV
using DataFrames: DataFrame

tulipa = TulipaData{String}()

# These are "default" for Norse, but not the default when populating with defaults
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

consumers = Dict(
    "Asgard_E_demand" => (peak_demand = 65787.17792,),
    "Midgard_E_demand" => (peak_demand = 19604.76443,),
    "Valhalla_E_exports" => (peak_demand = 50.0,),
    "Valhalla_H2_demand" => (peak_demand = 745.735,),
    "Valhalla_Heat_demand" => (peak_demand = 3548.42445,),
    "W_Spillage" => (peak_demand = 0.0,),
)

producers = Dict(
    "Asgard_Solar" => (
        capacity = 100.0,
        investment_group = "renewables",
        investable = true,
        investment_method = "simple",
        investment_integer = true,
        investment_cost = 350.0,
        investment_limit = 50000.0,
    ),
    "G_imports" => (capacity = 75000.0,),
    "Midgard_E_imports" => (capacity = 500.0,),
    "Midgard_Nuclear_SMR" => (
        capacity = 150.0,
        investable = true,
        investment_method = "simple",
        investment_integer = false,
        investment_cost = 6000.0,
    ),
    "Midgard_Wind" => (
        capacity = 3.0,
        investment_group = "renewables",
        investable = true,
        investment_method = "simple",
        investment_integer = true,
        investment_cost = 1300.0,
        investment_limit = 80000.0,
    ),
    "Valhalla_Waste_heat" => (capacity = 200.0, investment_cost = 1450), # should there be an investment_cost here?
)

converters = Dict(
    "Asgard_CCGT" => (
        capacity = 500.0,
        investment_group = "ccgt",
        min_operating_point = 0.25,
        investable = true,
        investment_method = "simple",
        investment_integer = true,
        investment_cost = 650.0,
        ramping = true,
        max_ramp_up = 0.5,
        max_ramp_down = 0.3,
    ),
    "Midgard_CCGT" =>
        (capacity = 500.0, investment_group = "ccgt", min_operating_point = 0.4),
)

### assets
add_asset!(
    tulipa,
    "ccgt",
    :producer,
    capacity = 400.0,
    investment_method = "simple",
    investment_integer = true,
    investable = true,
    investment_cost = 40.0,
    investment_limit = 10000.0,
    ;
    asset_extra_defaults...,
)
add_asset!(tulipa, "demand", :consumer, peak_demand = 1115.0, ; asset_extra_defaults...)
add_asset!(
    tulipa,
    "ens",
    :producer,
    capacity = 1115.0,
    initial_units = 1.0,
    ;
    asset_extra_defaults...,
)
add_asset!(
    tulipa,
    "ocgt",
    :producer,
    capacity = 100.0,
    investment_method = "simple",
    investment_integer = true,
    investable = true,
    investment_cost = 25.0,
    ;
    asset_extra_defaults...,
)
add_asset!(
    tulipa,
    "solar",
    :producer,
    description = "Solar",
    capacity = 10.0,
    resolution = 6,
    investment_method = "simple",
    investment_integer = true,
    investable = true,
    investment_cost = 50.0,
    ;
    asset_extra_defaults...,
)
add_asset!(
    tulipa,
    "wind",
    :producer,
    capacity = 50.0,
    investment_method = "simple",
    investment_integer = true,
    investable = true,
    investment_cost = 70.0,
    ;
    asset_extra_defaults...,
)

### flow
add_flow!(tulipa, "ccgt", "demand", operational_cost = 0.05, ; flow_extra_defaults...)
add_flow!(tulipa, "ens", "demand", operational_cost = 0.18, ; flow_extra_defaults...)
add_flow!(tulipa, "ocgt", "demand", operational_cost = 0.07, ; flow_extra_defaults...)
add_flow!(tulipa, "solar", "demand", ; flow_extra_defaults...)
add_flow!(tulipa, "wind", "demand", operational_cost = 0.001, ; flow_extra_defaults...)

### profiles

norse_profiles_path = joinpath(@__DIR__, "..", "test", "norse-profiles.csv")
df = DataFrame(CSV.File(norse_profiles_path))

attach_profile!(
    tulipa,
    "Argard_Solar",
    :availability,
    2030,
    df[!, "availability-Asgard_Solar"],
)
attach_profile!(
    tulipa,
    "Asgard_Valhalla_flow",
    :availability,
    2030,
    df[!, "availability-Valhalla_flow"],
)
attach_profile!(
    tulipa,
    "Midgard_Wind",
    :availability,
    2030,
    df[!, "availability-Midgard_Wind"],
)

attach_profile!(tulipa, "Asgard_E_demand", :demand, 2030, df[!, "demand-Asgard_E_demand"])
attach_profile!(tulipa, "Midgard_E_demand", :demand, 2030, df[!, "demand-Midgard_E_demand"])
attach_profile!(
    tulipa,
    "Valhalla_H2_demand",
    :demand,
    2030,
    df[!, "demand-Valhalla_H2_demand"],
)
attach_profile!(
    tulipa,
    "Valhalla_Heat_demand",
    :demand,
    2030,
    df[!, "demand-Valhalla_Heat_demand"],
)

attach_profile!(tulipa, "Midgard_Hydro", :demand, 2030, df[!, "inflows-Midgard_Hydro"])
# no profile for ocgt

connection = create_connection(tulipa)

# create_case_study_csv_folder(connection, joinpath(@__DIR__, "norse"))
# TODO: At the end, uncomment above and delete/move everything below

# External
using DuckDB: DuckDB
using TulipaClustering: TulipaClustering as TC
using TulipaEnergyModel: TulipaEnergyModel as TEM
using Test

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

unfixable_missing_columns = Dict(
    "asset" => ["min_operating_point", "max_ramp_down", "max_ramp_up"],
    "assets_profiles" => ["profile_name"],
)

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

period_duration = 24
num_rep_periods = 3
TC.cluster!(connection, period_duration, num_rep_periods)
TEM.populate_with_defaults!(connection)

# Comparison
norse_folder = joinpath(pkgdir(TEM), "test", "inputs", "Norse")
for file in readdir(norse_folder, join = true)
    table_name = replace(splitext(basename(file))[1], "-" => "_")
    # TODO: Try to make clustering more predictable to compare these tables as well
    if table_name in ["rep_periods_mapping", "profiles_rep_periods"]
        continue
    end
    DuckDB.query(connection, "CREATE TABLE expected_$table_name AS FROM read_csv('$file')")
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

    # TODO: Use @testset
    @info "Comparing $table_name"
    @info compare_duckdb_tables(connection, table_name, "expected_$table_name")
end
