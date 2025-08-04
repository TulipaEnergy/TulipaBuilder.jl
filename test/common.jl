@testmodule CommonSetup begin
    using TulipaEnergyModel: TulipaEnergyModel as TEM, run_scenario
    export TEM, run_scenario
    using JuMP
    export JuMP
    using DuckDB
    export DuckDB
    using DataFrames: DataFrame
    export DataFrame
end
