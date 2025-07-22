using DataFrames
using MetaGraphsNext
using TulipaEnergyModel: TulipaEnergyModel as TEM
using TulipaBuilder: TulipaBuilder as TB
using XLSX

tulipa = TB.TulipaData()

# TODO: Make the model feasible
# TODO: Remove as much as possible to create a minimum viable example

# Asset: OCGT
TB.add_asset!(tulipa, :ccgt, :producer, capacity = 225, investment_method = "simple")
TB.attach_milestone_data!(tulipa, :ccgt, 2030, initial_units = 1, investable = true)
TB.attach_commission_data!(
    tulipa,
    :ccgt,
    2030,
    fixed_cost = 1.0,
    investment_limit = 5,
    investment_cost = 35.0,
)

# Asset: Solar
TB.add_asset!(
    tulipa,
    :solar,
    :producer,
    description = "Stuff",
    capacity = 10.0,
    resolution = 6,
    investment_method = "simple",
)
TB.attach_milestone_data!(tulipa, :solar, 2030, initial_units = 1, investable = true)
TB.attach_commission_data!(
    tulipa,
    :solar,
    2030,
    fixed_cost = 1.0,
    investment_limit = 5,
    investment_cost = 35.0,
)

# Asset: OCGT
TB.add_asset!(tulipa, :ocgt, :producer, capacity = 250.0, investment_method = "simple")
TB.attach_milestone_data!(tulipa, :ocgt, 2030, initial_units = 1, investable = true)
TB.attach_commission_data!(
    tulipa,
    :ocgt,
    2030,
    fixed_cost = 10.0,
    investment_limit = 50,
    investment_cost = 10.0,
)

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

# TODO: I shouldn't have to do this
TB.attach_both_years_data!(tulipa, :ccgt, 2030, 2030)
TB.attach_both_years_data!(tulipa, :solar, 2030, 2030)
TB.attach_both_years_data!(tulipa, :ocgt, 2030, 2030)
TB.attach_both_years_data!(tulipa, :demand, 2030, 2030)
TB.attach_commission_data!(tulipa, :ccgt, :demand, 2030)
TB.attach_commission_data!(tulipa, :solar, :demand, 2030)
TB.attach_commission_data!(tulipa, :ocgt, :demand, 2030)

xls = XLSX.readtable(joinpath(@__DIR__, "test", "tulipatest.xlsx"), "profiles")
df = DataFrame(xls)

TB.attach_profile!(tulipa, :solar, :availability, 2030, df[!, "Solar"])
TB.attach_profile!(tulipa, :demand, :demand, 2030, df[!, "Demand"])
TB.attach_profile!(tulipa, :ccgt, :availability, 2030, 0.5 .+ 0.1 * randn(24))

# no profile for ocgt

connection = TB.create_connection(tulipa)

ep = TEM.run_scenario(connection, show_log = false)
