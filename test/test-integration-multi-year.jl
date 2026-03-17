@testsnippet MultiYearFixes begin
    # These are non-TEM-defaults that are constant across all years in the reference data
    asset_extra_defaults = (
        # asset
        technical_lifetime = 15,            # default is 1 (overridden per-asset where needed)
        discount_rate = 0.05,               # default is 0.0
        economic_lifetime = 10,             # default is 1
        # asset_milestone
        initial_storage_level = 0.0,        # default is null
    )
    flow_extra_defaults = (
        # flow
        discount_rate = 0.02,               # default is 0.0
        carrier = "electricity",            # default is null
        technical_lifetime = 10,            # default is 1
        # flow_commission (common to all flows/years in reference)
        investment_cost = 350.0,            # default is 0.0
    )

    unfixable_missing_columns = Dict(
        "asset" => ["min_operating_point", "max_ramp_down", "max_ramp_up"],
        "assets_profiles" => ["profile_name"],
    )
end

@testitem "Comparison of Multi-year Investments generated via TulipaBuilder" tags =
    [:integration] setup = [CommonSetup, MultiYearFixes] begin

    tulipa = TulipaData{String}()

    ### Non-milestone years (no profiles attached, must define length explicitly)
    # TODO: This is only used to create year-data.csv, which we realized
    # recently that we don't need in practice and that it could be removed.
    # This should be reevaluated after https://github.com/TulipaEnergy/TulipaEnergyModel.jl/issues/1356
    add_or_update_year!(tulipa, 2020, length = 8760)
    add_or_update_year!(tulipa, 2025, length = 8760)

    ### assets

    # battery: storage, simple investment
    add_asset!(
        tulipa,
        "battery",
        :storage;
        asset_extra_defaults...,
        capacity = 50.0,
        investable = true,
        investment_method = "simple",
        investment_integer = true,
        technical_lifetime = 30,
        capacity_storage_energy = 100.0,
        storage_method_energy = true,
        storage_charging_efficiency = 0.95,
        storage_discharging_efficiency = 0.95,
    )

    # ccgt: producer, semi-compact investment
    add_asset!(
        tulipa,
        "ccgt",
        :producer;
        asset_extra_defaults...,
        capacity = 400.0,
        investment_limit = 10000.0,
        investment_method = "semi-compact",
        investment_integer = true,
        technical_lifetime = 25,
    )

    # demand: consumer, no investment
    add_asset!(tulipa, "demand", :consumer; asset_extra_defaults..., peak_demand = 1115.0)

    # ens: producer, no investment
    add_asset!(tulipa, "ens", :producer; capacity = 1115.0, asset_extra_defaults...)

    # ocgt: producer, simple investment
    add_asset!(
        tulipa,
        "ocgt",
        :producer;
        capacity = 100.0,
        investable = true,
        investment_method = "simple",
        investment_integer = true,
        asset_extra_defaults...,
    )

    # solar: producer, simple investment
    add_asset!(
        tulipa,
        "solar",
        :producer;
        capacity = 10.0,
        investable = true,
        investment_method = "simple",
        investment_integer = true,
        asset_extra_defaults...,
    )

    # wind: producer, compact investment
    add_asset!(
        tulipa,
        "wind",
        :producer;
        asset_extra_defaults...,
        capacity = 50.0,
        investable = true,
        investment_method = "compact",
        investment_integer = true,
        technical_lifetime = 30,
    )

    ### asset_commission data (from asset-commission.csv)
    # Only attach non-TEM-default values (TEM defaults: fixed_cost=0, investment_cost=0,
    # fixed_cost_storage_energy=0, investment_cost_storage_energy=0,
    # conversion_efficiency=1, storage_charging/discharging_efficiency=1, storage_loss=0)

    # battery
    attach_commission_data!(
        tulipa,
        "battery",
        2030,
        fixed_cost = 23.0,
        investment_cost = 73.0,
        investment_cost_storage_energy = 3.0,
        fixed_cost_storage_energy = 35.0,
    )
    attach_commission_data!(
        tulipa,
        "battery",
        2050,
        fixed_cost = 25.0,
        investment_cost = 75.0,
        investment_cost_storage_energy = 5.0,
        fixed_cost_storage_energy = 55.0,
    )
    # ccgt (commission years: 2025, 2030, 2050)
    attach_commission_data!(
        tulipa,
        "ccgt",
        2025,
        fixed_cost = 31.0,
        investment_cost = 41.0,
        investment_limit = 10000.0,
    )
    attach_commission_data!(
        tulipa,
        "ccgt",
        2030,
        fixed_cost = 32.0,
        investment_cost = 42.0,
        investment_limit = 10000.0,
    )
    attach_commission_data!(
        tulipa,
        "ccgt",
        2050,
        fixed_cost = 33.0,
        investment_cost = 43.0,
        investment_limit = 10000.0,
    )
    # ocgt
    attach_commission_data!(tulipa, "ocgt", 2030, fixed_cost = 41.0, investment_cost = 25.0)
    attach_commission_data!(tulipa, "ocgt", 2050, fixed_cost = 42.0, investment_cost = 26.0)
    # solar
    attach_commission_data!(
        tulipa,
        "solar",
        2030,
        fixed_cost = 51.0,
        investment_cost = 51.0,
    )
    attach_commission_data!(
        tulipa,
        "solar",
        2050,
        fixed_cost = 52.0,
        investment_cost = 52.0,
    )
    # wind (commission years: 2020, 2030, 2050)
    attach_commission_data!(tulipa, "wind", 2020, fixed_cost = 61.0, investment_cost = 81.0)
    attach_commission_data!(tulipa, "wind", 2030, fixed_cost = 62.0, investment_cost = 82.0)
    attach_commission_data!(tulipa, "wind", 2050, fixed_cost = 63.0, investment_cost = 83.0)

    ### asset_both data (from asset-both.csv)
    # TEM defaults: decommissionable=false, initial_units=0, initial_storage_units=0
    # simple/none assets get same-year entries auto-populated, EXCEPT when non-default values needed

    # battery: simple — needs non-default decommissionable/initial_units
    attach_both_years_data!(
        tulipa,
        "battery",
        2030,
        2030,
        decommissionable = true,
        initial_units = 1.09,
    )
    attach_both_years_data!(
        tulipa,
        "battery",
        2050,
        2050,
        decommissionable = true,
        initial_units = 2.02,
    )
    # ccgt: semi-compact — must be set explicitly (no auto-population)
    attach_both_years_data!(tulipa, "ccgt", 2025, 2030, initial_units = 1.0)
    attach_both_years_data!(tulipa, "ccgt", 2030, 2030, initial_units = 1.0)
    attach_both_years_data!(tulipa, "ccgt", 2050, 2050, initial_units = 1.0)
    # ens: none — auto-populated, but needs non-default initial_units
    attach_both_years_data!(tulipa, "ens", 2030, 2030, initial_units = 1.0)
    attach_both_years_data!(tulipa, "ens", 2050, 2050, initial_units = 1.0)
    # wind: compact — must be set explicitly (no auto-population)
    attach_both_years_data!(
        tulipa,
        "wind",
        2020,
        2030,
        decommissionable = true,
        initial_units = 0.07,
    )
    attach_both_years_data!(tulipa, "wind", 2030, 2030, initial_units = 0.02)
    attach_both_years_data!(
        tulipa,
        "wind",
        2030,
        2050,
        decommissionable = true,
        initial_units = 0.02,
    )
    attach_both_years_data!(tulipa, "wind", 2050, 2050)

    ### flows (from flow.csv)
    # TEM defaults: capacity=0, is_transport=false, economic_lifetime=1, investment_integer=false
    add_flow!(tulipa, "ens", "demand"; flow_extra_defaults...)
    add_flow!(tulipa, "ocgt", "demand"; flow_extra_defaults...)
    add_flow!(tulipa, "demand", "battery"; flow_extra_defaults...)
    add_flow!(tulipa, "battery", "demand"; flow_extra_defaults...)
    add_flow!(
        tulipa,
        "ccgt",
        "demand";
        flow_extra_defaults...,
        is_transport = true,
        capacity = 100.0,
        technical_lifetime = 40,
    )
    add_flow!(tulipa, "wind", "demand"; flow_extra_defaults...)
    add_flow!(tulipa, "solar", "demand"; flow_extra_defaults...)

    ### flow_milestone data (from flow-milestone.csv)
    # TEM defaults: investable=false, operational_cost=0, commodity_price=0, reactance=0.3, dc_opf=false
    # Skip entries where all values are TEM defaults (battery↔demand, solar→demand)

    attach_milestone_data!(
        tulipa,
        "ccgt",
        "demand",
        2030,
        investable = true,
        operational_cost = 0.05,
        commodity_price = 10.0,
    )
    attach_milestone_data!(
        tulipa,
        "ccgt",
        "demand",
        2050,
        investable = true,
        operational_cost = 0.05,
        commodity_price = 20.0,
    )
    attach_milestone_data!(tulipa, "ens", "demand", 2030, operational_cost = 0.18)
    attach_milestone_data!(tulipa, "ens", "demand", 2050, operational_cost = 0.18)
    attach_milestone_data!(
        tulipa,
        "ocgt",
        "demand",
        2030,
        operational_cost = 0.07,
        commodity_price = 10.0,
    )
    attach_milestone_data!(
        tulipa,
        "ocgt",
        "demand",
        2050,
        operational_cost = 0.07,
        commodity_price = 20.0,
    )
    attach_milestone_data!(tulipa, "wind", "demand", 2030, operational_cost = 0.001)
    attach_milestone_data!(tulipa, "wind", "demand", 2050, operational_cost = 0.001)

    ### flow_commission data (from flow-commission.csv)
    # investment_cost=350.0 is propagated via flow_extra_defaults for all flows/years
    # TEM defaults: capacity_coefficient=1, conversion_coefficient=1, fixed_cost=0, producer_efficiency=1
    # Skip entries where all values match defaults (including the propagated investment_cost=350.0)

    attach_commission_data!(
        tulipa,
        "ccgt",
        "demand",
        2025,
        fixed_cost = 2.0,
        investment_cost = 350.0,
        investment_limit = 100.0,
        capacity_coefficient = 0.8,
        producer_efficiency = 0.5,
    )
    attach_commission_data!(
        tulipa,
        "ccgt",
        "demand",
        2030,
        fixed_cost = 2.0,
        investment_limit = 100.0,
        capacity_coefficient = 0.9,
    )
    attach_commission_data!(
        tulipa,
        "ccgt",
        "demand",
        2050,
        fixed_cost = 3.0,
        investment_limit = 100.0,
    )
    attach_commission_data!(tulipa, "demand", "battery", 2030, producer_efficiency = 0.2)
    attach_commission_data!(tulipa, "ens", "demand", 2050, producer_efficiency = 0.4)
    attach_commission_data!(tulipa, "solar", "demand", 2030, producer_efficiency = 0.4)
    # wind commission_year 2020 exists due to attach_both_years_data!(wind, 2020, 2030, ...).
    # Registering this year triggers propagation of basic_data (e.g. investment_cost) from add_flow!
    attach_commission_data!(tulipa, "wind", "demand", 2020)
    attach_commission_data!(tulipa, "wind", "demand", 2030, producer_efficiency = 0.3)

    ### flow_both data for ccgt→demand transport flow (from flow-both.csv)
    # TEM defaults: decommissionable=false, initial_export_units=0, initial_import_units=0
    attach_both_years_data!(
        tulipa,
        "ccgt",
        "demand",
        2030,
        2030,
        decommissionable = true,
        initial_export_units = 1.0,
        initial_import_units = 1.0,
    )
    attach_both_years_data!(tulipa, "ccgt", "demand", 2050, 2050, decommissionable = true)

    ### profiles (using tiny-profiles.csv as source data; actual values don't affect metadata comparison)
    tiny_profiles_path = joinpath(@__DIR__, "..", "test", "tiny-profiles.csv")
    df = DataFrame(CSV.File(tiny_profiles_path))

    # wind availability profiles: commission_year 2020 at milestone 2030
    attach_profile!(
        tulipa,
        "wind",
        :availability,
        2030,
        df[!, "availability-wind"];
        commission_year = 2020,
    )
    # wind availability profiles at milestone 2030 (commission_year 2030)
    attach_profile!(tulipa, "wind", :availability, 2030, df[!, "availability-wind"])
    # wind availability profile at milestone 2050 (commission_year 2050)
    attach_profile!(tulipa, "wind", :availability, 2050, df[!, "availability-wind"])

    # solar availability profiles
    attach_profile!(tulipa, "solar", :availability, 2030, df[!, "availability-solar"])
    attach_profile!(tulipa, "solar", :availability, 2050, df[!, "availability-solar"])

    # demand profiles
    attach_profile!(tulipa, "demand", :demand, 2030, df[!, "demand-demand"])
    attach_profile!(tulipa, "demand", :demand, 2050, df[!, "demand-demand"])

    connection = create_connection(tulipa)

    # External clustering
    period_duration = 24
    num_rep_periods = 3
    TC.cluster!(
        connection,
        period_duration,
        num_rep_periods;
        layout = TC.ProfilesTableLayout(year = :milestone_year),
    )
    # NOTE: TC.cluster! assigns rep period IDs globally across all years, so year 2050 gets IDs
    # 4-6 (continuing from 2030's 1-3). The reference data (rep_periods_data) expects IDs 1-3
    # per year, so we're manually fixing it.
    # TODO: Create issue to decide if the data needs to change or the TC output
    DuckDB.query(
        connection,
        """
        CREATE OR REPLACE TABLE rep_periods_data AS
        SELECT
            * EXCLUDE (rep_period),
            rep_period - min(rep_period) OVER (PARTITION BY milestone_year) + 1 AS rep_period
        FROM rep_periods_data
        """,
    )
    TEM.populate_with_defaults!(connection)

    # Comparison
    multi_year_folder = joinpath(pkgdir(TEM), "test", "inputs", "Multi-year Investments")
    for file in readdir(multi_year_folder, join = true)
        table_name = replace(splitext(basename(file))[1], "-" => "_")
        # Skip clustering-specific tables (depend on exact profile values used)
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
