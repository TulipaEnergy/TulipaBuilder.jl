# Basic tutorial

This tutorial goes over a creation of a simple Tulipa problem, with the following:

- 1 generator, with 1 existing unit, and capacity for 500 KW;
- 1 consumer, with fake demand around 400 KW.

```@example basic
using TulipaBuilder
```

The first step is to create a `TulipaData` object.

```@example basic
tulipa = TulipaData()
```

Then, we add each asset with their respective characteristics.

```@example basic
add_asset!(tulipa, "generator", :producer, capacity = 500.0, initial_units = 1.0)
add_asset!(tulipa, "consumer", :consumer, peak_demand = 500.0)
```

Next, we define the flow between these assets and the operational cost:

```@example basic
add_flow!(tulipa, "generator", "consumer", operational_cost = 5.00)
```

Now, let's attach the profiles to the solar and demand assets.
Notice that we need to pass the year in which these profiles are defined.
In a single-year problem, the year doesn't matter, so any integer value could be used.

```@example basic
num_timesteps = 24
demand_profile = (400 .+ randn(num_timesteps) * 20) / 500
attach_profile!(tulipa, "consumer", :demand, 2030, demand_profile)
```

Now we can create the connection with the data of the Tulipa problem using the `create_connection` function.

```@example basic
connection = create_connection(tulipa)

# Inspect all tables in DuckDB
using DuckDB, DataFrames
DuckDB.query(connection, "SELECT table_name, estimated_size, column_count FROM duckdb_tables()") |> DataFrame
```

Optionally, you might also want to create a folder with the data in CSV format:

```@example basic
output_folder = mktempdir() # Define the output folder
create_case_study_csv_folder(connection, output_folder)

readdir(output_folder)
```

For completeness, here is rest of the pipeline for clustering, populating with defaults, and solving the problem:

```@example basic
# Don't forget to cluster and populate with defaults before solving the problem
using TulipaEnergyModel, TulipaClustering

dummy_cluster!(connection)
populate_with_defaults!(connection)
ep = run_scenario(connection)
```
