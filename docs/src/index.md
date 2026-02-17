```@meta
CurrentModule = TulipaBuilder
```

# TulipaBuilder

[TulipaBuilder](https://github.com/TulipaEnergy/TulipaBuilder.jl) aims to make it easy to create a [Tulipa](https://github.com/TulipaEnergy/TulipaEnergyModel.jl) problem.
It provides a graph-based constructive interface to defining the assets and flows of an energy system, their respective data, and profiles.
The interface is **heavily** tied to [TulipaEnergyModel's input schema](https://tulipaenergy.github.io/TulipaEnergyModel.jl/stable/20-user-guide/54-input-table-schemas/), but it glosses over the complexity.

!!! warning
    TulipaBuilder is still in development, and there is no guarantee that it is creating the model that you expect. Please check the output and open issues if you see something wrong.
