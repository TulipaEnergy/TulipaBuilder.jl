# TulipaBuilder.jl 0.1.0 Release Preparation Plan

**Date Created**: 2025-12-18
**Estimated Total Time**: ~7.25 hours

## Overview

This plan addresses critical issues blocking a stable 0.1.0 release, with a focus on:

1. **Excessive warnings** during normal operation (user experience issue)
2. **Documentation gaps** (docstrings, tutorials, index.md)
3. **Hidden quality issues** (TODOs, API inconsistencies, missing exports)

---

## Critical Issues Summary

### 1. EXCESSIVE WARNINGS (Highest Priority - User Experience)

**Problem**: Users see flood of warnings during normal model creation due to schema-driven design intentionally ignoring unknown columns.

**Files Affected**:

- `src/create-connection.jl:239` - Debug `@warn columns` statement (MUST REMOVE)
- `src/create-connection.jl:148, 184, 219, 256, 287, 327, 366, 405` - Schema validation warnings for every unknown property

**Root Cause**: The schema-driven design intentionally ignores columns that don't exist in the current TulipaEnergyModel version. These warnings fire for every property that doesn't exist in the schema, flooding logs during normal operation.

**Solution**: Convert all schema warnings to `@debug` level - users can enable with `ENV["JULIA_DEBUG"] = "TulipaBuilder"` if needed. This maintains diagnostic capability while not polluting user logs during normal operation.

---

### 2. DOCUMENTATION GAPS

#### 2.1 Missing Docstrings (All Exported Functions)

**Files Requiring Docstrings**:

- `src/structures/tulipa-asset.jl:105` - `attach_profile!(asset, profile_type, year, profile_value)`
- `src/structures/tulipa-data.jl:21` - `add_or_update_year!(tulipa, year; kwargs...)`
- `src/structures/tulipa-data.jl:32, 41` - `add_asset!(tulipa, asset::TulipaAsset)` and `add_asset!(tulipa, name, type; kwargs...)`
- `src/structures/tulipa-data.jl:83, 92` - `add_flow!(tulipa, flow::TulipaFlow)` and `add_flow!(tulipa, from, to; kwargs...)`
- `src/structures/tulipa-data.jl:51-135` - All `attach_*_data!()` wrapper functions
- `src/structures/tulipa-data.jl:137` - `attach_profile!(tulipa, asset_name, profile_type, year, profile_value)`
- `src/create-connection.jl:448` - `create_connection(tulipa::TulipaData)`
- `src/output.jl:1` - `create_case_study_csv_folder(connection, folder_path)`

**Struct Documentation Needed**:

- `src/structures/tulipa-asset.jl:1` - `TulipaAsset` struct
- `src/structures/tulipa-flow.jl:2` - `TulipaFlow` struct
- `src/structures/tulipa-data.jl:3` - `TulipaData` struct

**Docstring Style**: Simple, concise format for 0.1.0:

- Header with function signature
- One sentence description of what the function does
- Basic parameter list if needed
- Keep examples minimal or defer to tutorial (post-0.1.0)

#### 2.2 Documentation Files

**Files to Update**:

1. `docs/src/index.md` - Currently only 8-line stub
   - Add: Concise package overview (2-3 paragraphs)
   - Add: Installation instructions (1 code block)
   - Add: Link to examples and API reference
   - Keep it brief - defer comprehensive tutorial to post-0.1.0

2. `docs/src/91-developer.md` - Currently only 3-line stub
   - Add: Brief architecture overview (graph-based, schema-driven)
   - Add: Link to CLAUDE.md for detailed development info
   - Add: Testing command reference
   - Keep concise - defer detailed explanations to post-0.1.0

**Deferred to Post-0.1.0**:

- Comprehensive tutorial with step-by-step walkthrough
- Detailed developer guide with internal architecture

#### 2.3 README.md Updates

**Current Issue**: Line 38 states "WIP: None of these are correctly tested" for magic transformations.

**Action**: Either:

- Add comprehensive tests for magic transformations, then remove WIP note
- OR document which aspects are tested vs. untested with GitHub issue links

---

### 3. API CONSISTENCY & MISSING EXPORTS

#### 3.1 Missing Function Exports

**File**: `src/TulipaBuilder.jl`

**Functions NOT exported but should be**:

- `create_connection` - Core workflow function, used in all examples
- `add_or_update_year!` - Documented in CLAUDE.md as public API

**Action**: Add both to export list.

#### 3.2 TulipaFlow API Inconsistencies (BREAKING CHANGE - Include in 0.1.0)

**File**: `src/structures/tulipa-flow.jl:23-39`

**Issues**:

1. Functions don't return the flow object (unlike TulipaAsset counterparts)
2. Missing `on_conflict` parameter (unlike TulipaAsset versions)

**Impact**:

- Cannot chain operations on flows
- Flow data silently overwrites without user control

**Solution**: Add return values and `on_conflict` parameter to match TulipaAsset API pattern. This is a breaking change but acceptable for 0.1.0 to establish correct API from the start.

---

### 4. CODE QUALITY ISSUES

#### 4.1 Production Code Issues

**Critical**:

- `src/create-connection.jl:239` - Debug `@warn columns` (DELETE THIS LINE)
- `src/structures/tulipa-asset.jl:84` - `@assert` used for validation (replace with proper `error()`)
- `src/structures/tulipa-flow.jl:37` - `@assert` used for validation (replace with proper `error()`)

**Rationale**: `@assert` statements are removed in production builds; use `error()` for proper validation.

#### 4.2 Error Message Quality

**File**: `src/structures/tulipa-data.jl:34, 85`

**Current**: Generic "Asset exists" / "Flow exists" errors

**Improvement**: Include asset/flow name: `error("Asset '$name' already exists in the model")`

#### 4.3 TODOs Without Resolution (REQUIRES REVIEW)

**File**: `src/create-connection.jl`

**Unresolved TODOs**:

- Line 61: `asset_both` limitation (milestone_year=commission_year only)
- Line 99: Commented flow_both propagation code
- Line 131: "This is a terrible way of doing this" - column collection logic
- Line 485: "Evaluate CREATE OR REPLACE alternative"

**Action**: Must review these during implementation to determine:

- Are they blocking issues or acceptable limitations?
- Do they require TulipaEnergyModel clarification?
- Should they be documented as known limitations or fixed?

**Note**: These will be addressed case-by-case during Phase 1 implementation.

#### 4.4 Code Duplication in create_connection

**File**: `src/create-connection.jl:115-546`

**Issue**: Near-identical blocks for 8 tables (asset, asset_both, asset_commission, asset_milestone, flow, flow_both, flow_commission, flow_milestone) - each ~60-100 lines.

**Recommendation for 0.1.0**: Document as technical debt for post-0.1.0 refactoring. Refactoring this is risky before release.

---

### 5. TESTING GAPS

#### 5.1 Missing Integration Test

**Gap**: `examples/demolipa.jl` has no corresponding integration test

**Action**: Create `test/test-integration-demolipa.jl` similar to `test-integration-tiny.jl`

#### 5.2 Magic Transformations Testing

**Current State**: README.md:38 admits "WIP: None of these are correctly tested"

**Required Tests**:

- Property propagation from `add_asset!()` to year-specific tables
- Automatic (asset, year) and (flow, year) combination filling
- `asset_both` population from `asset_milestone`
- Year creation from profiles and attach functions

**Status Check**: Some tests exist in `test/test-year-data-determination.jl` but coverage should be verified.

---

### 6. DEPENDENCY & COMPATIBILITY

#### 6.1 Version Bounds Issues

**File**: `Project.toml:14-21`

**Current Issues**:

- Exact versions specified: DataFrames = "1.7.0", DuckDB = "1.3.1", MetaGraphsNext = "0.7.3"
- Should use ranges like "1.7" to allow compatible patch updates
- TulipaEnergyModel supports multiple versions but no upper bound

**Recommendation**: Review and adjust version bounds for flexibility while maintaining compatibility.

---

### 7. EXAMPLE FILES CLEANUP

**Files to Handle**:

- `examples/tmp-ex1.jl`
- `examples/tmp-jump-tutorial.jl`
- `examples/tmp-rolling-horizon.jl`

**Action**: Either remove `tmp-` prefix and properly document, or delete if not needed for release.

---

## Implementation Plan

### Phase 1: Critical Fixes (Blockers) - MUST FIX

**Estimated Time: 1.5 hours**

- [ ] 1. **Remove debug warning** (5 min)
  - Delete `src/create-connection.jl:239` (`@warn columns`)

- [ ] 2. **Convert schema warnings to @debug** (30 min)
  - Convert 8 schema validation warnings in `create-connection.jl` to `@debug`
  - Test that models build without warning spam

- [ ] 3. **Review and address TODOs** (30 min)
  - Review each TODO in `create-connection.jl` (lines 61, 99, 131, 485)
  - Determine if blocking, needs documentation, or can defer
  - Document decisions inline or create GitHub issues

- [ ] 4. **Fix @assert validation** (15 min)
  - Replace `@assert` with proper `error()` in:
    - `src/structures/tulipa-asset.jl:84`
    - `src/structures/tulipa-flow.jl:37`
  - Add descriptive error messages

- [ ] 5. **Add missing exports** (5 min)
  - Export `create_connection` and `add_or_update_year!` in `src/TulipaBuilder.jl`

- [ ] 6. **Improve error messages** (5 min)
  - Update `src/structures/tulipa-data.jl:34, 85` to include asset/flow names

### Phase 2: API Consistency - MUST FIX for Stable API

**Estimated Time: 1 hour**

- [ ] 7. **Fix TulipaFlow API inconsistencies** (1 hour)
  - Add `return flow` to attach_*_data! functions
  - Add `on_conflict` parameter matching TulipaAsset pattern
  - Update tests if needed

### Phase 3: Minimal Documentation - HIGH PRIORITY

**Estimated Time: 2 hours**

- [ ] 8. **Add simple docstrings to all exported functions** (1 hour)
  - Format: Header with signature + one sentence description
  - Priority: Core workflow functions first (create_connection, add_asset!, add_flow!, attach_profile!)
  - Then: Data attachment functions and structs

- [ ] 9. **Update docs/src/index.md** (30 min)
  - Concise package overview (2-3 paragraphs)
  - Installation instructions
  - Link to examples folder and API reference

- [ ] 10. **Update docs/src/91-developer.md** (30 min)
  - Brief architecture overview
  - Link to CLAUDE.md for details
  - Testing command reference

### Phase 4: Testing & Validation - MEDIUM PRIORITY

**Estimated Time: 2 hours**

- [ ] 11. **Create demolipa integration test** (1 hour)
  - Add `test/test-integration-demolipa.jl`
  - Verify demolipa example works end-to-end

- [ ] 12. **Verify magic transformation test coverage** (1 hour)
  - Review existing tests in `test/test-year-data-determination.jl`
  - Add missing edge cases if identified
  - Update README.md:38 to remove WIP note or document what remains

### Phase 5: Cleanup - LOW PRIORITY

**Estimated Time: 45 min**

- [ ] 13. **Handle tmp example files** (15 min)
  - Decide to keep, rename, or delete
  - Document decision

- [ ] 14. **Create GitHub issues for deferred work** (30 min)
  - Code duplication refactoring for post-0.1.0
  - Comprehensive tutorial creation
  - Detailed developer guide
  - Version bounds review

---

## Key Files to Modify

1. `src/create-connection.jl` - Warning fixes, @assert replacements
2. `src/structures/tulipa-data.jl` - Error message improvements
3. `src/structures/tulipa-asset.jl` - @assert fix, docstrings
4. `src/structures/tulipa-flow.jl` - @assert fix, API consistency, docstrings
5. `src/TulipaBuilder.jl` - Missing exports
6. `src/output.jl` - Docstrings
7. `docs/src/index.md` - Concise update
8. `docs/src/91-developer.md` - Brief update
9. `test/test-integration-demolipa.jl` - New file

---

## Success Criteria for 0.1.0

**Must Have**:

- [ ] Models build without warning spam (only intentional warnings)
- [ ] All exported functions have simple docstrings (header + one sentence)
- [ ] Core structs documented
- [ ] Index.md provides concise package introduction
- [ ] No debug statements in production code
- [ ] Proper error handling (no @assert for validation)
- [ ] API consistency between TulipaAsset and TulipaFlow
- [ ] Both major examples (tiny, demolipa) have integration tests
- [ ] All functions used in examples are properly exported
- [ ] TODOs reviewed and addressed or documented

**Deferred to Post-0.1.0**:

- [ ] Comprehensive tutorial with step-by-step walkthrough
- [ ] Detailed developer guide with internal architecture
- [ ] Docstrings with extensive examples

---

## Post-0.1.0 Recommendations

**High Priority for 0.1.1**:

- Create comprehensive tutorial with simplified tiny example
- Expand developer guide with internal architecture details
- Add extensive examples to key docstrings

**Medium Priority**:

- Refactor create_connection() duplication into helper functions
- Review and update dependency version bounds
- Add error handling tests
- Consider profile validation in attach_profile!

**Low Priority**:

- Resolve remaining TODOs or create architectural decision records
