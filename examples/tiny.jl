#=
    Example: Tiny data from TulipaEnergyModel (no defaults, no clustering)

    Manually recreate the Tiny data from TulipaEnergyModel, without populating with defaults

    Running:

        julia --project=examples examples/tiny.jl
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

tiny_profiles_path = joinpath(@__DIR__, "..", "test", "tiny-profiles.csv")
df = DataFrame(CSV.File(tiny_profiles_path))

attach_profile!(tulipa, "solar", :availability, 2030, df[!, "availability-solar"])
attach_profile!(tulipa, "demand", :demand, 2030, df[!, "demand-demand"])
attach_profile!(tulipa, "wind", :availability, 2030, df[!, "availability-wind"])
# no profile for ocgt

connection = create_connection(tulipa)

create_case_study_csv_folder(connection, joinpath(@__DIR__, "tiny"))
