# Basic example with renewable producer and battery and scenarios

This tutorial goes over a creation of a simple Tulipa problem, with the following:

- 1 thermal generator, with 1 existing unit, and capacity for 500 KW;
- 1 solar generator, with 1 existing unit, capacity for 200 KW and an availability profile named "solar";
- 1 consumer, with peak demand of 500 KW, and a demand profile named "demand";
- 1 battery node;
- The profiles per scenario are stored in a CSV file.

```@example scenarios
using TulipaBuilder
```

The first step is to create a `TulipaData` object.

```@example scenarios
tulipa = TulipaData()
```

Then, we add each asset with their respective characteristics.

```@example scenarios
add_asset!(tulipa, "thermal", :producer, capacity = 500.0, initial_units = 1.0)
add_asset!(tulipa, "solar", :producer, capacity = 200.0, initial_units = 1.0)
add_asset!(tulipa, "demand", :consumer, peak_demand = 500.0)
add_asset!(tulipa, "battery", :storage)
```

Next, we need to define the flows between these assets, and the operational cost, if defined.

```@example scenarios
add_flow!(tulipa, "thermal", "demand", operational_cost = 0.05)
add_flow!(tulipa, "solar", "demand")
add_flow!(tulipa, "demand", "battery")
add_flow!(tulipa, "battery", "demand")
```

To visualise the network using the internal graph, please check the tutorial [Basic example with renewable producer and battery](@ref basic_renewable_battery).

Let's load the profiles from a CSV file and explore the data.
The scenarios here represent different weather years, e.g.,

```@example scenarios
using CSV
using DataFrames

profiles_data = joinpath(@__DIR__, "..", "..", "..", "test", "tiny-profiles-scenarios.csv")
df = DataFrame(CSV.File(profiles_data))

# Group by scenario and plot first week for each scenario
using Plots
plt = plot()
grouped = groupby(df, :scenario)
linestyles = [:solid, :dash, :dot, :dashdot]
for (i, scenario_df) in enumerate(grouped)
    scenario_name = scenario_df.scenario[1]
    ls = linestyles[mod1(i, length(linestyles))]
    plot!(
        plt,
        scenario_df[1:168, "solar"],
        c = :orange,
        lw = 2,
        alpha = 0.7,
        label = "solar ($scenario_name)",
        linestyle = ls,
    )
    plot!(
        plt,
        scenario_df[1:168, "demand"],
        c = :green,
        lw = 2,
        alpha = 0.7,
        label = "demand ($scenario_name)",
        linestyle = ls,
    )
end
plot!(
    plt,
    legend = :outerbottom,
    legendcolumns = 2,
    title = "Profiles for different weather years (scenarios)",
)
xlabel!(plt, "Hour")
ylabel!(plt, "Profile value (pu)")
plt
```

Now, let's attach the profiles to the solar and demand assets for each scenario.

!!! note "Multiple dispatch in Julia"
    The function `attach_profile!` has multiple methods to handle attaching the profiles with and without scenarios. Notice that in the loop below, we are using the method that includes the scenario name, so the profiles are attached to each scenario. If we had used the method without the scenario name, the profiles would have been attached to a default scenario (with value `1`), and thus shared across all scenarios. For and example of attaching profiles without scenarios, please check the tutorial [Basic example with renewable producer and battery](@ref basic_renewable_battery). Please check the [reference](@ref reference) section for more information about this function.

```@example scenarios
year = 2030
for scenario_df in grouped
    scenario_name = scenario_df.scenario[1]
    solar_profile = Vector(scenario_df[!, "solar"])
    demand_profile = Vector(scenario_df[!, "demand"])
    attach_profile!(tulipa, "solar", :availability, year, scenario_name, solar_profile)
    attach_profile!(tulipa, "demand", :demand, year, scenario_name, demand_profile)
end
```

Now we can create the connection with the data of the Tulipa problem using the `create_connection` function.

```@example scenarios
connection = create_connection(tulipa)
```

Let's check the inserted profiles in the `profiles` table, which now contains the scenario information. Here we summarize the mean value per scenario and profile name to verify that the data was correctly inserted.

```@example scenarios
using DuckDB
tulipa_profiles = DuckDB.query(connection, "FROM profiles") |> DataFrame

# summarize per scenario and profile_name
using Statistics
combine(groupby(tulipa_profiles, [:scenario, :profile_name]), :value => mean => :mean_value)
```

Notice that the profile names are automatically created from the attached data in the `assets_profiles` table, but the scenario column is not included there since it is implied by the profiles attached to each asset:

```@example scenarios
using DuckDB
DuckDB.query(connection, "FROM assets_profiles") |> DataFrame
```
