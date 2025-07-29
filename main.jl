using DataFrames
using DuckDB
using MetaGraphsNext
using TulipaEnergyModel: TulipaEnergyModel as TEM
using TulipaBuilder: TulipaBuilder as TB
using XLSX

tulipa = TB.TulipaData()

### assets
# Asset: CCGT
# Investable will allow this to be used
# Capacity > 0 means it's useful
# investment_limit is inf so it scales as much as needed
# investment_cost must be positive
TB.add_asset!(
    tulipa,
    :ccgt,
    :producer,
    capacity = 2.0,
    investment_method = "simple",
    investable = true,
    investment_cost = 3.0,
)

# Asset: Solar
# Not investable: initial_units > 0 and capacity > 0
TB.add_asset!(
    tulipa,
    :solar,
    :producer,
    description = "Solar",
    capacity = 1.0,
    resolution = 6,
)
TB.attach_both_years_data!(tulipa, :solar, 2030, 2030, initial_units = 10)

# Asset: OCGT
TB.add_asset!(
    tulipa,
    :ocgt,
    :producer,
    capacity = 3.0,
    investment_method = "simple",
    investable = true,
    investment_cost = 4.0,
)

# Asset: Demand
TB.add_asset!(tulipa, :demand, :consumer, peak_demand = 30.0)

### flow
TB.add_flow!(tulipa, :solar, :demand)
for asset in (:ccgt, :ocgt)
    TB.add_flow!(tulipa, asset, :demand)
end

### profiles

xls = XLSX.readtable(joinpath(@__DIR__, "test", "tulipatest.xlsx"), "profiles")
df = DataFrame(xls)

TB.attach_profile!(tulipa, :solar, :availability, 2030, df[!, "Solar"])
TB.attach_profile!(tulipa, :demand, :demand, 2030, df[!, "Demand"])
TB.attach_profile!(tulipa, :ccgt, :availability, 2030, 0.5 .+ 0.1 * randn(24))

# no profile for ocgt

connection = TB.create_connection(tulipa)

ep = TEM.run_scenario(connection, show_log = false, model_file_name = "model.lp")
