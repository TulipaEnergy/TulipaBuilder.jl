# Basic example with renewable producer and battery

This tutorial goes over a creation of a simple Tulipa problem, with the following:

- 1 thermal generator, with 1 existing unit, and capacity for 500 KW;
- 1 solar generator, with 1 existing unit, capacity for 200 KW and an availability profile named "solar";
- 1 consumer, with peak demand of 500 KW, and a demand profile named "demand";
- 1 battery node;
- The profiles are stored in a CSV file.

```@example basic
using TulipaBuilder
```

The first step is to create a `TulipaData` object.

```@example basic
tulipa = TulipaData()
```

Then, we add each asset with their respective characteristics.

```@example basic
add_asset!(tulipa, "thermal", :producer, capacity = 500.0, initial_units = 1.0)
add_asset!(tulipa, "solar", :producer, capacity = 200.0, initial_units = 1.0)
add_asset!(tulipa, "demand", :consumer, peak_demand = 500.0)
add_asset!(tulipa, "battery", :storage)
```

Next, we need to define the flows between these assets, and the operational cost, if defined.

```@example basic
add_flow!(tulipa, "thermal", "demand", operational_cost = 0.05)
add_flow!(tulipa, "solar", "demand")
add_flow!(tulipa, "demand", "battery")
add_flow!(tulipa, "battery", "demand")
```

At this point, we can visualise the network using the internal graph.
Note that this is optional, and you can just skip ahead.

```@example basic
# OPTIONAL: Plotting the graph
using Karnak
using Colors
using MetaGraphsNext

graph = tulipa.graph
assets = collect(labels(graph))
color_per_type = Dict(:producer => colorant"red", :consumer => colorant"green", :storage => colorant"blue")

function vertexfillcolors(vtx)
    asset = assets[vtx]
    asset_type = graph[asset].type
    return color_per_type[asset_type]
end

@drawsvg begin
    background("lightblue")
    sethue("black")
    drawgraph(
        graph.graph,
        edgegaps = 20,
        vertexlabels = assets,
        vertexfillcolors = vertexfillcolors,
        vertexshapes = (vtx) -> box(O, 6.5 * length(assets[vtx]), 20, :fill),
        vertexlabeltextcolors = colorant"white",
    )
end 600 400
```

Now, let's attach the profiles to the solar and demand assets.
Notice that we need to pass the year in which these profiles are defined.
In a single-year problem, the year doesn't matter, so any integer value could be used.

```@example basic
using CSV
using DataFrames

profiles_data = joinpath(@__DIR__, "..", "..", "..", "test", "tiny-profiles.csv")
df = DataFrame(CSV.File(profiles_data))
attach_profile!(tulipa, "solar", :availability, 2030, df[!, "availability-solar"])
attach_profile!(tulipa, "demand", :demand, 2030, df[!, "demand-demand"])

using Plots
plt = plot()
plot!(plt, df[!, "availability-solar"], c=:orange, lw=2, label="solar")
plot!(plt, df[!, "demand-demand"], c=:green, lw=2, label="demand")
```

Now we can create the connection with the data of the Tulipa problem using the `create_connection` function.

```@example basic
connection = create_connection(tulipa)
```

Notice that the profile names are automatically created from the attached data:

```@example basic
using DuckDB

DuckDB.query(connection, "FROM assets_profiles") |> DataFrame
```
