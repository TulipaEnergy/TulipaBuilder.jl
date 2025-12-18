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

**Primary Testing (CLI Runner)**: `julia --project=test test/runtests.jl`
**Traditional tesing**: `julia --project=test -e 'using Pkg; Pkg.test()'`
**Filtered Testing**: `julia --project=test test/runtests.jl --tags fast --exclude slow`

The test runner supports filtering by:

- `--tags tag1,tag2`: Run tests with ALL specified tags
- `--exclude tag1,tag2`: Skip tests with ANY specified tags
- `--file filename`: Run tests from files containing substring
- `--name testname`: Run tests whose name contains substring
- `--pattern text`: Run tests with name/filename containing pattern
- `--list-tags`: Show available tags
- `--help`: Show usage help

### Running the examples

```bash
julia --project=examples examples/FILE.jl
```

### Package development

```bash
# Activate the project environment
julia --project=.

# Install/update dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.update()'
```

### Documentation

```bash
# Build documentation locally
julia --project=docs docs/make.jl
```

## Core Workflow Pattern

The main workflow creates a graph-based model and converts it to TulipaEnergyModel's database format:

### Simple Workflow (Most Common)

1. **Initialize**: Create a `TulipaData{Symbol}()` instance
2. **Build Graph**:
   - Add assets using `add_asset!(tulipa, name, type, property=value, ...)` - properties automatically apply to all years
   - Add flows using `add_flow!(tulipa, from_asset, to_asset, property=value, ...)` - properties automatically apply to all years
3. **Add Profiles**: Use `attach_profile!(tulipa, asset, profile_type, year, data)` for time-series data
   - **REQUIRED**: At least one profile per year for optimization to work
   - Profiles automatically mark years as milestone years and set year length
4. **Convert to Database**: `create_connection(tulipa)` converts the graph to DuckDB format
   - Automatically propagates asset/flow properties to all year-specific tables
   - Automatically fills missing (asset, year) and (flow, year) combinations
5. **Export (Optional)**: `create_case_study_csv_folder(connection, folder_path)` exports to CSV files
6. **Solve**: Run `TulipaEnergyModel.run_scenario(connection)` on the resulting connection

### Advanced Workflow (Year-Specific Overrides)

Only needed when you want different property values for specific years:

- `attach_milestone_data!(tulipa, asset, year, property=value)` - Override properties for a milestone year
- `attach_commission_data!(tulipa, asset, year, property=value)` - Override properties for a commission year
- `attach_both_years_data!(tulipa, asset, milestone_year, commission_year, property=value)` - Set investment-specific data

These override the automatically propagated values from `add_asset!()` or `add_flow!()`.

### Automatic Transformations ("Magic")

TulipaBuilder performs several automatic transformations to simplify the user experience:

1. **Year Tracking**: Years are automatically created when you attach profiles or year-specific data
   - `attach_profile!()` marks the year as a milestone year and sets year length
   - `attach_milestone_data!()` marks the year as a milestone year

2. **Property Propagation**: Properties passed to `add_asset!()` and `add_flow!()` automatically propagate to all year-specific tables
   - Called via `propagate_year_data!()` inside `create_connection()`
   - Uses schema validation to only propagate valid columns per table
   - Respects manually attached year-specific data (doesn't overwrite)

3. **Missing Year Combinations**: Automatically creates entries for all (asset, year) and (flow, year) combinations
   - Milestone tables get entries only for milestone years
   - Commission tables get entries for all years
   - Uses schema defaults for unspecified columns

4. **Asset Both Table**: Automatically populates `asset_both` table from `asset_milestone` for non-compact methods
   - Sets commission_year = milestone_year (same year)
   - Ensures data structure consistency

5. **Schema-Driven Tables**: All tables created dynamically from TulipaEnergyModel.schema
   - Only includes columns that exist in the current TEM version
   - Applies schema defaults automatically

### Key Conversion Process (create_connection)

The `create_connection()` function is the bridge between TulipaBuilder's graph representation and TulipaEnergyModel's database format. It:

- Dynamically creates tables (asset, asset_both, asset_commission, asset_milestone, flow, flow_both, flow_commission, flow_milestone, profiles, assets_profiles, year_data) based on `TulipaEnergyModel.schema`
- Only includes columns that exist in the current schema version
- Converts graph data to SQL insertions with proper type casting
- Handles profiles as separate tables with timestep-based indexing

## Important Dependencies

- **TulipaEnergyModel**: The solver backend - provides the schema and solves the optimization model
- **MetaGraphsNext**: Graph data structure for representing the energy system as assets (vertices) and flows (edges)
- **DataFrames**: Data manipulation for profiles and results
- **DuckDB**: In-memory database for the final data format expected by TulipaEnergyModel
- **TulipaIO**: I/O operations and SQL formatting utilities
- **Graphs**: Base graph functionality

## File Structure

### Core Source Files

- `src/TulipaBuilder.jl`: Main module with exports
- `src/structures/`: Core data structures (TulipaAsset, TulipaFlow, TulipaData)
- `src/create-connection.jl`: Conversion to TulipaEnergyModel format (includes `propagate_year_data!()`)
- `src/output.jl`: CSV export functionality (`create_case_study_csv_folder`)
- `src/utils.jl`: Utility functions

### Examples and Tests

- `examples/tiny.jl`: Minimal working example recreating TulipaEnergyModel's Tiny dataset
- `examples/demolipa.jl`: Larger example with YAML configuration loading
- `test/runtests.jl`: Test runner with CLI filtering support
- `test/test-*.jl`: Focused test suites for different functionality

## Development Guidelines

### CRITICAL

- Always sign-off commits with a `Co-authored-by: Claude Code (FULL MODEL VERSION) <noreply@anthropic.com>` - for example: `Co-authored-by: Claude Code (claude-sonnet-4-20250514) <noreply@anthropic.com>`

### Schema Compatibility Rules

1. **Never hardcode column names** except for the core required ones (asset, type, from_asset, to_asset, commission_year, milestone_year)
2. **Always check schema existence** with `haskey(TulipaEnergyModel.schema[table_name], key)` before using columns
3. **Let TulipaEnergyModel.schema define** column types and defaults dynamically
4. **Propagation is automatic**: Properties in `add_asset!()` and `add_flow!()` automatically propagate to year-specific tables via `propagate_year_data!()`
5. **Year-specific overrides**: Use `attach_*_data!()` functions only when you need different values for specific years

### Common Data Patterns

Assets can be:

- **producers** (e.g., :ccgt, :solar, :ocgt) - generate energy
- **consumers** (e.g., :demand) - consume energy

Key properties are schema-driven but commonly include:

- `capacity`: Asset capacity
- `investment_method`: "simple" for investable assets
- `investable`: Boolean for milestone years
- `investment_cost`: Cost for commission years

The exact required fields depend on the TulipaEnergyModel version being used. The automatic propagation system handles most cases without explicit year-specific data attachment - properties passed to `add_asset!()` and `add_flow!()` are automatically propagated to all years.

**Year Requirements for Well-Defined Models**:

- At least one year must be defined (future versions may include a default for simpler usage)
- Years are automatically created when calling functions with a `year` parameter (e.g., `attach_profile!()`, `attach_milestone_data!()`)
- The year length must be defined, either:
  - Implicitly by attaching a profile (uses the profile's length)
  - Explicitly using `add_or_update_year!(tulipa, year, length=value)`

### Testing Guidelines

The project uses TestItem.jl with tags for selective test execution during development.

#### Test Organization

- **File naming**: `test/test-[functionality].jl` for focused test suites
- **Descriptive names**: Test names should clearly state what behavior is being verified
- **Appropriate tags**: Use `:unit`, `:integration`, `:fast` for filtering during development
- **Logical grouping**: Group related test scenarios within the same file

#### Test Dependencies

- **Add to test environment**: New testing dependencies go in `test/Project.toml`
- **Export in common setup**: Make dependencies available via `test/common.jl`
- **Follow existing patterns**: Use the established `[CommonSetup]` pattern for shared setup

#### Test Content Focus

- **Behavior verification**: Test what the code does, not how it does it
- **Schema compatibility**: Tests should work across different TulipaEnergyModel versions
- **Full workflow coverage**: Include integration tests that exercise `create_connection()` and complete user workflows
- **Edge cases**: Test boundary conditions, error scenarios, and data combinations
- **Self-contained**: Each test should be independent and not rely on execution order

## Testing Strategy

### Development Workflow

**During Development**: Use filtered testing to focus on relevant tests only

```bash
# Test specific functionality during development
julia --project=test test/runtests.jl --file test-year-data --tags fast
julia --project=test test/runtests.jl --tags unit,fast --exclude slow
```

**Before Commits**: Run full test suite to ensure no regressions

```bash
julia --project=test test/runtests.jl  # All tests via CLI runner
julia --project=test -e 'using Pkg; Pkg.test()'  # Full Pkg.test()
```

### Testing Architecture Patterns

#### TestItems Organization

- **Strategy-per-testitem**: Create focused testitems for each major component/strategy rather than nested loops
- **Shared testsnippets**: Use `@testsnippet` for per-test setup (runs each time, variables directly accessible)
- **Shared testmodules**: Use `@testmodule` for one-time expensive operations like data loading/computation (runs once, accessed via module prefix)
- **Combined approach**: Use both when needed - testmodules for shared expensive operations, testsnippets for per-test variables
- **Comprehensive validation**: Each testitem should test multiple aspects (files, dependencies, behavior) in one place

#### Pattern Examples

**@testsnippet (per-test setup):**

```julia
@testsnippet TestData begin
  tulipa = TulipaData{Symbol}()  # Fresh instance each test
  add_asset!(tulipa, :test_asset, :producer)
end

@testitem "Feature works" setup=[CommonSetup, TestData] begin
  @test haskey(tulipa.graph, :test_asset)
end
```

**@testmodule (one-time expensive operations):**

```julia
@testmodule SharedAssets begin
  const COMPLEX_TULIPA = create_complex_test_model()  # Create once
  const REFERENCE_CONNECTION = create_connection(COMPLEX_TULIPA)  # Compute once
end

@testitem "Validation works" setup=[CommonSetup, SharedAssets] begin
  @test validate_against(result, SharedAssets.REFERENCE_CONNECTION)
end
```

#### CLI Filtering for Development

- **Semantic tags**: Use descriptive tags like `:unit`, `:integration`, `:fast` for easy filtering
- **Development workflow**: `julia --project=test test/runtests.jl --file specific_file` during development
- **Add new tags to TAGS_DATA**: Update `test/runtests.jl` when introducing new tag categories

#### Key Development Rule

**When testing new tests, use the CLI approach to filter only the relevant files to test.**
