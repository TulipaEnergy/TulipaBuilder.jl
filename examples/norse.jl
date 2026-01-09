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
    set_partition!,
    create_connection,
    create_case_study_csv_folder
using CSV: CSV
using DataFrames: DataFrame, combine, groupby, nrow, groupindices

tulipa = TulipaData{String}()

# These are "default" for Norse, but not the default when populating with defaults
# TODO: Open discussion in TEM on whether these should be kept or not
asset_extra_defaults = (
    # asset_commission
    fixed_cost_storage_energy = 5.0,    # default is 0.0
    # asset
    technical_lifetime = 15,            # default is 1
    discount_rate = 0.05,               # default is 0.0
)
flow_extra_defaults = (
    # flow
    technical_lifetime = 10,            # default is 1
    discount_rate = 0.02,               # default is 0.0
    investment_limit = 0.0,             # default is null
)

# producer assets
producers = Dict(
    "Asgard_Solar" => (;
        investment_group = "renewables",
        capacity = 100.0,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        investment_cost = 350.0,
        investment_limit = 50000.0,
    ),
    "G_imports" => (;
        capacity = 75000.0,
        decommissionable = true,
        initial_units = 1.0,
        investment_limit = 0.0,
    ),
    "Midgard_E_imports" => (;
        capacity = 500.0,
        decommissionable = true,
        initial_units = 1.0,
        investment_limit = 0.0,
    ),
    "Midgard_Nuclear_SMR" => (;
        capacity = 150.0,
        investment_method = "simple",
        is_seasonal = true,
        ramping = true,
        max_ramp_up = 0.75,
        max_ramp_down = 0.65,
        investable = true,
        min_energy_timeframe_partition = 4500.0,
        investment_cost = 6000.0,
        initial_units = 6.6666667,
    ),
    "Midgard_Wind" => (;
        investment_group = "renewables",
        capacity = 3.0,
        investment_method = "simple",
        investment_integer = true,
        is_seasonal = true,
        investable = true,
        max_energy_timeframe_partition = 4.5e6,
        investment_cost = 1300.0,
        investment_limit = 80000.0,
    ),
    "Valhalla_Waste_heat" =>
        (; capacity = 200.0, investment_cost = 1450, decommissionable = true),
)
for (asset, kwargs) in producers
    add_asset!(
        tulipa,
        asset,
        :producer;
        initial_storage_level = 0.0,
        kwargs...,
        asset_extra_defaults...,
    )
end

# consumer assets
consumers = Dict(
    "Asgard_E_demand" => (; peak_demand = 65787.17792, decommissionable = true),
    "Midgard_E_demand" => (; peak_demand = 19604.76443, decommissionable = true),
    "Valhalla_E_exports" => (; peak_demand = 50.0, decommissionable = true),
    "Valhalla_H2_demand" => (; peak_demand = 745.735, decommissionable = true),
    "Valhalla_Heat_demand" => (;
        consumer_balance_sense = ">=",
        peak_demand = 3548.42445,
        decommissionable = true,
    ),
    "W_Spillage" => (; consumer_balance_sense = ">=", initial_units = 1.0),
)
for (asset, kwargs) in consumers
    add_asset!(
        tulipa,
        asset,
        :consumer;
        investment_limit = 0.0,
        initial_storage_level = 0.0,
        kwargs...,
        asset_extra_defaults...,
    )
end

# conversion assets
# ccgt converters
add_asset!(
    tulipa,
    "Asgard_CCGT",
    :conversion,
    investment_group = "ccgt",
    capacity = 500.0,
    investment_cost = 650.0,
    min_operating_point = 0.25,
    investment_method = "simple",
    investment_integer = true,
    ramping = true,
    max_ramp_up = 0.5,
    max_ramp_down = 0.3,
    investable = true,
    unit_commitment = true,
    unit_commitment_method = "basic",
    units_on_cost = 0.97,
    conversion_efficiency = 0.55;
    initial_storage_level = 0.0,
    asset_extra_defaults...,
)
add_asset!(
    tulipa,
    "Midgard_CCGT",
    :conversion,
    investment_group = "ccgt",
    capacity = 500.0,
    investment_cost = 650.0,
    min_operating_point = 0.4,
    unit_commitment = true,
    unit_commitment_integer = true,
    unit_commitment_method = "basic",
    conversion_efficiency = 0.5,
    decommissionable = true,
    initial_units = 5.0;
    initial_storage_level = 0.0,
    asset_extra_defaults...,
)
# other converters
other_converters = Dict(
    "Valhalla_Electrolyser" => (;
        capacity = 100.0,
        investment_cost = 1260.0,
        conversion_efficiency = 0.7,
        initial_units = 5.0,
    ),
    "Valhalla_Fuel_cell" =>
        (; capacity = 100.0, investment_cost = 800.0, conversion_efficiency = 0.5),
    "Valhalla_GT" => (;
        capacity = 500.0,
        investment_cost = 400.0,
        investment_limit = 100000.0,
        conversion_efficiency = 0.42,
    ),
    "Valhalla_H2_generator" =>
        (; capacity = 100.0, investment_cost = 479.0, conversion_efficiency = 0.6),
    "Valhalla_Heat_pump" =>
        (; capacity = 100.0, investment_cost = 300.0, conversion_efficiency = 4.0),
)
for (asset, kwargs) in other_converters
    add_asset!(
        tulipa,
        asset,
        :conversion,
        investment_method = "simple",
        investment_integer = true,
        investable = true,
        initial_storage_level = 0.0; # why not leave default?
        kwargs...,
        asset_extra_defaults...,
    )
end

# storage asset
storage = Dict(
    "Asgard_Battery" => (;
        capacity = 100.0,
        investment_method = "simple",
        investment_integer = true,
        capacity_storage_energy = 10.0,
        use_binary_storage_method = "binary",
        storage_method_energy = true,
        energy_to_power_ratio = 100.0,
        investment_integer_storage_energy = true,
        investable = true,
        investment_cost = 300.0,
        investment_limit = 25000.0,
        investment_cost_storage_energy = 30.0,
        investment_limit_storage_energy = 1000.0,
        storage_charging_efficiency = 0.95,
        storage_discharging_efficiency = 0.95,
        initial_units = 7.25,
    ),
    "Midgard_Hydro" => (;
        capacity = 250.0,
        capacity_storage_energy = 50000.0,
        is_seasonal = true,
        use_binary_storage_method = "relaxed_binary",
        storage_inflows = 10000.0,
        investment_cost = 1600.0,
        investment_limit = 0.0,
        storage_charging_efficiency = 0.7,
        storage_discharging_efficiency = 1.0,
        decommissionable = true,
        initial_units = 1.0,
        initial_storage_units = 1.0,
        initial_storage_level = 25000.0,
    ),
    "Midgard_PHS" => (;
        capacity = 200.0,
        investment_method = "simple",
        investment_integer = true,
        capacity_storage_energy = 100.0,
        storage_method_energy = true,
        energy_to_power_ratio = 1.0,
        investable = true,
        investment_cost = 800.0,
        investment_limit = 5000.0,
        investment_cost_storage_energy = 500.0,
        investment_limit_storage_energy = 1000.0,
        storage_charging_efficiency = 0.85,
        storage_discharging_efficiency = 0.85,
        initial_units = 1.75,
    ),
    "Valhalla_H2_storage" => (;
        capacity = 500.0,
        investment_method = "simple",
        investment_integer = true,
        capacity_storage_energy = 100.0,
        is_seasonal = true,
        energy_to_power_ratio = 10000.0,
        investment_integer_storage_energy = true,
        investable = true,
        investment_cost = 0.1,
        investment_cost_storage_energy = 10.0,
        storage_charging_efficiency = 0.98,
        storage_discharging_efficiency = 0.98,
    ),
)
for (asset, kwargs) in storage
    add_asset!(tulipa, asset, :storage; kwargs..., asset_extra_defaults...)
end

# hub assets
add_asset!(
    tulipa,
    "Valhalla_E_balance",
    :hub,
    investment_limit = 0.0,
    decommissionable = true,
    initial_storage_level = 0.0;
    asset_extra_defaults...,
)

### flow
transport_flows = Dict(
    ("Asgard_E_demand", "Midgard_E_demand") => (;
        investment_integer = true,
        investment_cost = 2000.0,
        investment_limit = 50000.0,
    ),
    ("Asgard_E_demand", "Valhalla_E_balance") => (;
        investment_cost = 5000.0,
        initial_export_units = 1.0,
        initial_import_units = 1.0,
    ),
    ("Midgard_E_demand", "Valhalla_E_balance") =>
        (; investment_integer = true, investment_cost = 3500.0),
)
for ((from_asset, to_asset), kwargs) in transport_flows
    add_flow!(
        tulipa,
        from_asset,
        to_asset,
        carrier = "electricity",
        discount_rate = 0.02,
        technical_lifetime = 10,
        is_transport = true,
        capacity = 1000.0,
        investable = true,
        ;
        kwargs...,
    )
end

electricity_flows = Dict(
    ("Asgard_Battery", "Asgard_E_demand") => (; operational_cost = 0.003),
    ("Asgard_CCGT", "Asgard_E_demand") => (;),
    ("Asgard_Solar", "Asgard_Battery") => (; operational_cost = 0.001),
    ("Asgard_Solar", "Asgard_E_demand") => (; operational_cost = 0.001),
    ("Midgard_CCGT", "Midgard_E_demand") => (;),
    ("Midgard_E_demand", "Midgard_Hydro") => (;),
    ("Midgard_E_demand", "Midgard_PHS") => (; operational_cost = 0.002),
    ("Midgard_E_imports", "Midgard_E_demand") => (; operational_cost = 0.02),
    ("Midgard_Hydro", "Midgard_E_demand") => (;),
    ("Midgard_Nuclear_SMR", "Midgard_E_demand") => (; operational_cost = 0.015),
    ("Midgard_PHS", "Midgard_E_demand") => (; operational_cost = 0.004),
    ("Midgard_Wind", "Midgard_E_demand") => (; operational_cost = 0.002),
    ("Valhalla_E_balance", "Valhalla_E_exports") => (;),
    ("Valhalla_E_balance", "Valhalla_Heat_pump") => (;),
    ("Valhalla_E_balance", "Valhalla_Electrolyser") => (;),
    ("Valhalla_Fuel_cell", "Valhalla_E_balance") => (;),
    ("Valhalla_GT", "Valhalla_E_balance") => (;),
)
for ((from_asset, to_asset), kwargs) in electricity_flows
    add_flow!(
        tulipa,
        from_asset,
        to_asset;
        carrier = "electricity",
        kwargs...,
        flow_extra_defaults...,
    )
end

gas_flows = Dict(
    ("G_imports", "Midgard_CCGT") => (;),
    ("G_imports", "Asgard_CCGT") => (;),
    ("G_imports", "Valhalla_GT") => (;),
    ("G_imports", "Valhalla_H2_generator") => (;),
)
for ((from_asset, to_asset), kwargs) in gas_flows
    add_flow!(
        tulipa,
        from_asset,
        to_asset;
        carrier = "gas",
        operational_cost = 0.0015,
        kwargs...,
        flow_extra_defaults...,
    )
end

heat_flows = Dict(
    ("Valhalla_Fuel_cell", "Valhalla_Heat_demand") => (;),
    ("Valhalla_Heat_pump", "Valhalla_Heat_demand") => (;),
    ("Valhalla_Waste_heat", "Valhalla_Heat_pump") =>
        (; operational_cost = 0.0025, conversion_coefficient = 0.25),
)
for ((from_asset, to_asset), kwargs) in heat_flows
    add_flow!(
        tulipa,
        from_asset,
        to_asset;
        carrier = "heat",
        kwargs...,
        flow_extra_defaults...,
    )
end

hydrogen_flows = Dict(
    ("Valhalla_Electrolyser", "Valhalla_H2_demand") => (;),
    ("Valhalla_H2_demand", "Valhalla_Fuel_cell") => (;),
    ("Valhalla_H2_demand", "Valhalla_H2_storage") => (;),
    ("Valhalla_H2_generator", "Valhalla_H2_demand") => (;),
    ("Valhalla_H2_storage", "Valhalla_H2_demand") => (;),
)
for ((from_asset, to_asset), kwargs) in hydrogen_flows
    add_flow!(
        tulipa,
        from_asset,
        to_asset;
        carrier = "hydrogen",
        kwargs...,
        flow_extra_defaults...,
    )
end

add_flow!(
    tulipa,
    "Midgard_Hydro",
    "W_Spillage",
    carrier = "water",
    operational_cost = 0.05,
    capacity_coefficient = 0,
    ;
    flow_extra_defaults...,
)

### profiles

norse_profiles_path = joinpath(@__DIR__, "..", "test", "norse-profiles.csv")
df = DataFrame(CSV.File(norse_profiles_path))

attach_profile!(
    tulipa,
    "Asgard_Solar",
    :availability,
    2030,
    df[!, "availability-Asgard_Solar"],
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
attach_profile!(tulipa, "Midgard_Hydro", :inflows, 2030, df[!, "inflows-Midgard_Hydro"])

# Flows profiles
attach_profile!(
    tulipa,
    "Asgard_E_demand",
    "Valhalla_E_balance",
    :availability,
    2030,
    df[!, "availability-Asgard_Valhalla_flow"],
)

# Partitions
set_partition!(tulipa, "Asgard_Solar", 2030, 1, 4)
set_partition!(tulipa, "Asgard_E_demand", 2030, 1, "explicit", "7;7;7;21;21;21;21;21;21;21")
set_partition!(tulipa, "Midgard_Wind", 2030, 1, "math", "20x1+16x2+12x3+10x4+8x5")

set_partition!(tulipa, "Asgard_Battery", "Asgard_E_demand", 2030, 1, "math", "28x3+42x2")
set_partition!(tulipa, "Asgard_Solar", "Asgard_Battery", 2030, 1, "math", "42x2+28x3")
set_partition!(tulipa, "Asgard_Solar", "Asgard_Battery", 2030, 2, "math", "4x3+3x4")
set_partition!(tulipa, "Asgard_Solar", "Asgard_E_demand", 2030, 2, "math", "3x4+4x3")

connection = create_connection(tulipa)

create_case_study_csv_folder(connection, joinpath(@__DIR__, "norse"))
