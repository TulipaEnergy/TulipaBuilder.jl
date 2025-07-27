using DataFrames
using MetaGraphsNext
using TulipaEnergyModel: TulipaEnergyModel as TEM
using TulipaBuilder: TulipaBuilder as TB
using XLSX

tulipa = TB.TulipaData()

# Tinier test in TB form

# asset
TB.add_asset!(
    tulipa,
    :ccgt,
    :producer,
    capacity = 400.0,
    investment_method = "simple",
    investment_integer = true,
    technical_lifetime = 15,
    discount_rate = 0.05,
)
TB.add_asset!(
    tulipa,
    :demand,
    :consumer,
    # capacity = 0.0,
    # investment_method = "none",
    # investment_integer = false,
    # technical_lifetime = 15,
    # discount_rate = 0.05,
)
TB.add_asset!(
    tulipa,
    :ens,
    :producer,
    capacity = 1115.0,
    investment_method = "none",
    investment_integer = false,
    technical_lifetime = 15,
    discount_rate = 0.05,
)
TB.add_asset!(
    tulipa,
    :ocgt,
    :producer,
    capacity = 100.0,
    investment_method = "simple",
    investment_integer = true,
    technical_lifetime = 15,
    discount_rate = 0.05,
)
TB.add_asset!(
    tulipa,
    :solar,
    :producer,
    capacity = 10.0,
    investment_method = "simple",
    investment_integer = true,
    technical_lifetime = 15,
    discount_rate = 0.05,
)
TB.add_asset!(
    tulipa,
    :wind,
    :producer,
    capacity = 50.0,
    investment_method = "simple",
    investment_integer = true,
    technical_lifetime = 15,
    discount_rate = 0.05,
)

# asset-commission
TB.attach_commission_data!(
    tulipa,
    :ccgt,
    2030,
    investment_cost = 40.0,
    investment_limit = 10000.0,
    fixed_cost_storage_energy = 5.0,
)
TB.attach_commission_data!(
    tulipa,
    :wind,
    2030,
    investment_cost = 70.0,
    fixed_cost_storage_energy = 5.0,
)
TB.attach_commission_data!(
    tulipa,
    :solar,
    2030,
    investment_cost = 50.0,
    fixed_cost_storage_energy = 5.0,
)
TB.attach_commission_data!(
    tulipa,
    :demand,
    2030,
    # investment_cost = 0.0,
    fixed_cost_storage_energy = 5.0,
)
TB.attach_commission_data!(
    tulipa,
    :ocgt,
    2030,
    investment_cost = 25.0,
    fixed_cost_storage_energy = 5.0,
)
TB.attach_commission_data!(
    tulipa,
    :ens,
    2030,
    # investment_cost = 0.0,
    fixed_cost_storage_energy = 5.0,
)

# asset-milestone
TB.attach_milestone_data!(tulipa, :ccgt, 2030, investable = true)
TB.attach_milestone_data!(tulipa, :wind, 2030, investable = true)
TB.attach_milestone_data!(tulipa, :solar, 2030, investable = true)
TB.attach_milestone_data!(tulipa, :demand, 2030, peak_demand = 1115.0)
TB.attach_milestone_data!(tulipa, :ocgt, 2030, investable = true)
TB.attach_milestone_data!(tulipa, :ens, 2030)

# asset-both
TB.attach_both_years_data!(tulipa, :ocgt, 2030, 2030)
TB.attach_both_years_data!(tulipa, :ccgt, 2030, 2030)
TB.attach_both_years_data!(tulipa, :wind, 2030, 2030)
TB.attach_both_years_data!(tulipa, :solar, 2030, 2030)
TB.attach_both_years_data!(tulipa, :ens, 2030, 2030, initial_units = 1)
TB.attach_both_years_data!(tulipa, :demand, 2030, 2030)

# Asset: Demand
TB.add_asset!(tulipa, :demand, :consumer)
TB.attach_milestone_data!(tulipa, :demand, 2030, peak_demand = 30.0, investable = false)
TB.attach_commission_data!(tulipa, :demand, 2030, fixed_cost = 1.0)

TB.add_flow!(tulipa, :solar, :demand, capacity = 10.0)
# WHY
TB.attach_milestone_data!(tulipa, :solar, :demand, 2030, variable_cost = 5.0)
for asset in (:ccgt, :ocgt)
    TB.add_flow!(tulipa, asset, :demand, capacity = 5.0)
    # WHY
    TB.attach_milestone_data!(tulipa, asset, :demand, 2030, variable_cost = 5.0)
end


xls = XLSX.readtable(joinpath(@__DIR__, "test", "tulipatest.xlsx"), "profiles")
df = DataFrame(xls)

TB.attach_profile!(tulipa, :solar, :availability, 2030, df[!, "Solar"])
TB.attach_profile!(tulipa, :demand, :demand, 2030, df[!, "Demand"])
TB.attach_profile!(tulipa, :ccgt, :availability, 2030, 0.5 .+ 0.1 * randn(24))

# no profile for ocgt

connection = TB.create_connection(tulipa)

ep = TEM.run_scenario(connection, show_log = false, model_file_name = "model.lp")
