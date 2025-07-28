# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TulipaBuilder.jl is a Julia package that provides a **graph-based constructive user interface for TulipaEnergyModel.jl**. The primary goal is to create the simplest possible way for users to build energy system models that are compatible with TulipaEnergyModel.jl.

The package uses a graph-based approach where assets (producers, consumers) are vertices and flows are edges, with MetaGraphsNext.jl as the underlying data structure. The entire system is **schema-driven** - it dynamically uses `TulipaEnergyModel.schema` (which corresponds to the input-schemas.json file in TulipaEnergyModel.jl) to ensure compatibility across different versions.

## Target Users

1. **End-users** looking to create a Tulipa model with the most convenience possible
2. **Developers** looking to generate new case studies at scale to assist with benchmarking, testing, and validations

## Key Architecture Components

### Core Data Structures

- **TulipaData**: Main data structure containing a MetaGraph with assets as vertices and flows as edges
- **TulipaAsset**: Represents energy assets (producers, consumers) with properties dynamically based on schema
- **TulipaFlow**: Represents energy flows between assets with schema-driven properties
- **Time-based data**: Uses PerYear and PerYears dictionaries for milestone and commission data across different years
- **Profiles**: Time-series data (availability, demand) attached to assets for specific years

### Schema-Driven Design Philosophy

**CRITICAL**: The package avoids hardcoding column names from TulipaEnergyModel schemas to maintain compatibility across versions. Only required columns (like "asset", "type", "from_asset", "to_asset") are hardcoded.

- All table creation uses `TulipaEnergyModel.schema` to dynamically determine column types and defaults
- Functions check `haskey(TulipaEnergyModel.schema[table_name], key)` before using columns
- Unknown columns are ignored with warnings rather than causing errors
- This allows the same TulipaBuilder code to work with different TulipaEnergyModel versions

## Essential Commands

### Testing

```bash
julia --project=test -e 'using Pkg; Pkg.test()'
```

### Running the main example

```bash
julia --project=. main.jl
```

### Package development

```bash
# Activate the project environment
julia --project=.

# Install/update dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.resolve()'
```

### Documentation

```bash
# Build documentation locally
julia --project=docs docs/make.jl
```

## Core Workflow Pattern

The main workflow creates a graph-based model and converts it to TulipaEnergyModel's database format:

1. **Initialize**: Create a `TulipaData()` instance
2. **Build Graph**:
   - Add assets using `add_asset!(tulipa, name, type, ...)`
   - Add flows between assets using `add_flow!(tulipa, from_asset, to_asset)`
3. **Attach Time-Specific Data**:
   - `attach_milestone_data!()` for milestone years (investment decisions)
   - `attach_commission_data!()` for commission years (operational data)
   - `attach_both_years_data!()` for data spanning both commission and milestone years
4. **Add Profiles**: Use `attach_profile!(tulipa, asset, profile_type, year, data)` for time-series data
5. **Convert to TulipaEnergyModel Format**: `create_connection(tulipa)` converts the graph to DuckDB tables matching TulipaEnergyModel's expected schema
6. **Solve**: Run `TulipaEnergyModel.run_scenario(connection)` on the resulting connection

### Key Conversion Process (create_connection)

The `create_connection()` function is the bridge between TulipaBuilder's graph representation and TulipaEnergyModel's database format. It:

- Dynamically creates tables (asset, asset_both, asset_commission, asset_milestone, flow, flow_both, flow_commission, flow_milestone, profiles, assets_profiles, year_data) based on `TulipaEnergyModel.schema`
- Only includes columns that exist in the current schema version
- Converts graph data to SQL insertions with proper type casting
- Handles profiles as separate tables with timestep-based indexing

## Important Dependencies

- **TulipaEnergyModel**: The solver backend (aliased as TulipaEnergyModel) - provides the schema and solves the optimization model
- **MetaGraphsNext**: Graph data structure for representing the energy system as assets (vertices) and flows (edges)
- **DataFrames**: Data manipulation for profiles and results
- **DuckDB**: In-memory database for the final data format expected by TulipaEnergyModel
- **TulipaIO**: I/O operations and SQL formatting utilities (aliased as TIO)
- **TulipaClustering**: Clustering operations for time aggregation (currently uses dummy clustering)

## File Structure

- `src/TulipaBuilder.jl`: Main module with exports
- `src/structures/`: Core data structures (TulipaAsset, TulipaFlow, TulipaData)
- `src/create-connection.jl`: Conversion to TulipaEnergyModel format
- `main.jl`: Working example showing typical usage
- `test/runtests.jl`: Main test suite demonstrating the API

## Development Guidelines

### CRITICAL

- Always sign-off commits with a `Co-authored-by: Claude Code (FULL MODEL VERSION) <noreply@anthropic.com>` - for example: `Co-authored-by: Claude Code (claude-sonnet-4-20250514) <noreply@anthropic.com>`

### Schema Compatibility Rules

1. **Never hardcode column names** except for the core required ones (asset, type, from_asset, to_asset, commission_year, milestone_year)
2. **Always check schema existence** with `haskey(TulipaEnergyModel.schema[table_name], key)` before using columns
3. **Let TulipaEnergyModel.schema define** column types and defaults dynamically

### Common Data Patterns

Assets can be:

- **producers** (e.g., :ccgt, :solar, :ocgt) - generate energy
- **consumers** (e.g., :demand) - consume energy

Key properties are schema-driven but commonly include:

- `capacity`: Asset capacity
- `investment_method`: "simple" for investable assets
- `investable`: Boolean for milestone years
- `investment_cost`: Cost for commission years

All assets require proper milestone and commission data attachment for valid models. The exact required fields depend on the TulipaEnergyModel version being used.
