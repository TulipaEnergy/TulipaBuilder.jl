# Used to create the rolling horizon test case
using DuckDB
using TulipaClustering
using TulipaEnergyModel
using TulipaIO
using TulipaBuilder

# We are using TulipaBuilder as main development tool because we need RP = 1

tulipa = TulipaData{String}()

generators = ["G1", "G2"]
for generator in generators
    asset_name = generator
    add_asset!(tulipa, asset_name, :producer; capacity = 150.0, initial_units = 1.0)
end
add_asset!(
    tulipa,
    "base load",
    :consumer;
    peak_demand = 100.0,
    consumer_balance_sense = "==",
)

### flow
for generator in generators
    asset_name = generator
    add_flow!(tulipa, asset_name, "base load", operational_cost = 50.0)
end

### profiles
attach_profile!(tulipa, "base load", :demand, 2030, ones(24))


connection = create_connection(tulipa)

### clustering
dummy_cluster!(connection)

### populate_with_defaults
# populate_with_defaults!(connection)

TulipaBuilder.create_case_study_csv_folder(connection, "JuMPTest")
