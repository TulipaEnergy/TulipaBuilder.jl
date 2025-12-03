# Used to create the rolling horizon test case
using TulipaClustering
using TulipaEnergyModel
# using TulipaIO
using TulipaBuilder
using YAML
using CSV
using DataFrames

# We are using TulipaBuilder as main development tool because we need RP = 1

tulipa = TulipaData{String}()

data_path = joinpath(@__DIR__, "demolipa")
generator_config_path = joinpath(data_path, "generator_configs")
capacity_factors_file = joinpath(data_path, "capacity-factors.csv")

generators = readdir(generator_config_path)
config_dicts = Dict()
for fname in generators 
    config_full = YAML.load_file(joinpath(generator_config_path, fname))
    config = Dict()
    config["capacity"] = config_full["Generators"]["installed_capacity"]
    config["operational_cost"] = config_full["Generators"]["marginal_cost_linear"]
    config["profile_name"] = config_full["Generators"]["availability_factor"]
    asset_name = config_full["Generators"]["id"]
    config_dicts[asset_name] = config
end

for (asset_name, config) in config_dicts
    add_asset!(tulipa, asset_name, :producer; capacity = config["capacity"], initial_units = 0.0)
end

add_asset!(
    tulipa,
    "bid_manager",
    :consumer;
    peak_demand = 0.0,
    consumer_balance_sense = "==",
)

### flows
for (asset_name, config) in config_dicts
    add_flow!(tulipa, asset_name, "bid_manager", operational_cost = config["operational_cost"])
end

# ### profiles
df = DataFrame(CSV.File(capacity_factors_file))

for (asset_name, config) in config_dicts
    profile = df[!, config["profile_name"]]
    attach_profile!(tulipa, asset_name, :availability, 2030, profile)
end

connection = create_connection(tulipa)

### clustering
dummy_cluster!(connection)

### populate_with_defaults
# populate_with_defaults!(connection)

TulipaBuilder.create_case_study_csv_folder(connection, "demolipa")
