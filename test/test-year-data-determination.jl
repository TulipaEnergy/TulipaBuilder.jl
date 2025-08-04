@testitem "Basic profile attachment creates year_data automatically" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    tulipa = TulipaData()

    # Add a basic asset
    add_asset!(tulipa, :solar, :producer)

    # Initially, no years should be tracked
    @test isempty(tulipa.years)

    # Attach a profile to year 2030
    profile_data = rand(24)  # 24 timesteps
    attach_profile!(tulipa, :solar, :availability, 2030, profile_data)

    # Verify year_data was automatically created
    @test haskey(tulipa.years, 2030)
    @test length(tulipa.years) == 1

    # Verify the length was determined from profile
    @test tulipa.years[2030][:length] == 24

    # Verify the year was marked as milestone (profiles create milestone years)
    @test tulipa.years[2030][:is_milestone] == true
end

@testitem "Commission data attachment creates year_data automatically" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    tulipa = TulipaData()

    # Add a basic asset
    add_asset!(tulipa, :ccgt, :producer)

    # Initially, no years should be tracked
    @test isempty(tulipa.years)

    # Attach commission data to year 2025
    attach_commission_data!(tulipa, :ccgt, 2025, capacity = 100.0)

    # Verify year_data was automatically created
    @test haskey(tulipa.years, 2025)
    @test length(tulipa.years) == 1

    # Commission data should not create the :is_milestone key at all
    @test !haskey(tulipa.years[2025], :is_milestone)

    # Commission data doesn't provide length information
    @test !haskey(tulipa.years[2025], :length)
end

@testitem "Milestone data attachment creates year_data automatically" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    tulipa = TulipaData()

    # Add a basic asset
    add_asset!(tulipa, :wind, :producer)

    # Initially, no years should be tracked
    @test isempty(tulipa.years)

    # Attach milestone data to year 2035
    attach_milestone_data!(tulipa, :wind, 2035, investable = true)

    # Verify year_data was automatically created
    @test haskey(tulipa.years, 2035)
    @test length(tulipa.years) == 1

    # Milestone data should mark year as milestone
    @test haskey(tulipa.years[2035], :is_milestone)
    @test tulipa.years[2035][:is_milestone] == true

    # Milestone data doesn't provide length information
    @test !haskey(tulipa.years[2035], :length)
end

@testitem "Both_years data attachment creates year_data automatically" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    tulipa = TulipaData()

    # Add a basic asset
    add_asset!(tulipa, :hydro, :producer)

    # Initially, no years should be tracked
    @test isempty(tulipa.years)

    # Attach both_years data (commission_year=2025, milestone_year=2030)
    attach_both_years_data!(tulipa, :hydro, 2025, 2030, initial_units = 5)

    # Verify both years were automatically created
    @test haskey(tulipa.years, 2025)  # commission year
    @test haskey(tulipa.years, 2030)  # milestone year
    @test length(tulipa.years) == 2

    # Commission year should not be marked as milestone
    @test !haskey(tulipa.years[2025], :is_milestone)

    # Milestone year should be marked as milestone
    @test haskey(tulipa.years[2030], :is_milestone)
    @test tulipa.years[2030][:is_milestone] == true

    # Neither year gets length information from both_years data
    @test !haskey(tulipa.years[2025], :length)
    @test !haskey(tulipa.years[2030], :length)
end

@testitem "Mixed data sources for same year combine properly" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    tulipa = TulipaData()

    # Add a basic asset
    add_asset!(tulipa, :nuclear, :producer)

    # Mix different data attachment methods for the same year
    attach_commission_data!(tulipa, :nuclear, 2030, capacity = 1000.0)
    @test haskey(tulipa.years, 2030)
    @test !haskey(tulipa.years[2030], :is_milestone)

    # Adding milestone data should mark as milestone
    attach_milestone_data!(tulipa, :nuclear, 2030, investable = true)
    @test tulipa.years[2030][:is_milestone] == true

    # Adding profile should add length but preserve milestone status
    profile_data = rand(24)
    attach_profile!(tulipa, :nuclear, :availability, 2030, profile_data)
    @test tulipa.years[2030][:length] == 24
    @test tulipa.years[2030][:is_milestone] == true

    # Should still have only one year
    @test length(tulipa.years) == 1
end

@testitem "Flow data attachment creates year_data automatically" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    tulipa = TulipaData()

    # Add assets and flow
    add_asset!(tulipa, :gas, :producer)
    add_asset!(tulipa, :demand, :consumer)
    add_flow!(tulipa, :gas, :demand)

    # Initially, no years should be tracked
    @test isempty(tulipa.years)

    # Attach flow commission data
    attach_commission_data!(tulipa, :gas, :demand, 2025, capacity = 50.0)
    @test haskey(tulipa.years, 2025)
    @test !haskey(tulipa.years[2025], :is_milestone)

    # Attach flow milestone data
    attach_milestone_data!(tulipa, :gas, :demand, 2030, investable = true)
    @test haskey(tulipa.years, 2030)
    @test tulipa.years[2030][:is_milestone] == true

    # Attach flow both_years data
    attach_both_years_data!(tulipa, :gas, :demand, 2035, 2040, efficiency = 0.95)
    @test haskey(tulipa.years, 2035)  # commission
    @test haskey(tulipa.years, 2040)  # milestone
    @test !haskey(tulipa.years[2035], :is_milestone)
    @test tulipa.years[2040][:is_milestone] == true

    @test length(tulipa.years) == 4
end

@testitem "Integration test - demonstrates current system constraint with profiles" tags =
    [:integration, :fast] setup = [CommonSetup] begin
    # IMPORTANT: This test documents a current system constraint:
    # All years used in optimization MUST have profiles (which provide :length)
    # Since profiles always mark years as milestone, all functional years become milestone years
    # Commission-only years exist but cannot be used in create_connection() without profiles

    tulipa = TulipaData()

    add_asset!(tulipa, :solar, :producer, investment_method = "simple")
    add_asset!(tulipa, :demand, :consumer)
    add_flow!(tulipa, :solar, :demand)

    # Create a commission-only year (no profile = no length = non-functional)
    attach_commission_data!(tulipa, :solar, 2025, capacity = 100.0)
    @test haskey(tulipa.years, 2025)
    @test !haskey(tulipa.years[2025], :is_milestone)  # Commission year, not milestone
    @test !haskey(tulipa.years[2025], :length)        # No length = non-functional

    # Create a milestone year (also needs profile to be functional)
    attach_milestone_data!(tulipa, :solar, 2030, investable = true)
    @test haskey(tulipa.years, 2030)
    @test tulipa.years[2030][:is_milestone] == true   # Milestone year
    @test !haskey(tulipa.years[2030], :length)        # Still no length = non-functional

    # Demonstrate the constraint: create_connection fails on years without length
    @test_throws r"Not possible to determine length of year \d+\. Try attaching a profile" begin
        create_connection(tulipa)
    end

    # To make years functional, must add profiles (which makes them milestone)
    attach_profile!(tulipa, :solar, :availability, 2025, rand(24))   # Commission year + profile → milestone
    attach_profile!(tulipa, :demand, :demand, 2030, rand(100))      # Milestone year + profile → milestone

    # Now both years are functional and milestone (system constraint)
    @test tulipa.years[2025][:is_milestone] == true  # Profile made it milestone
    @test tulipa.years[2025][:length] == 24          # Profile provided length
    @test tulipa.years[2030][:is_milestone] == true  # Was already milestone, profile preserved it
    @test tulipa.years[2030][:length] == 100         # Profile provided length

    # Now create_connection works
    connection = create_connection(tulipa)

    # Verify year_data table reflects the constraint
    year_data_df =
        DuckDB.query(connection, "SELECT * FROM year_data ORDER BY year") |> DataFrame
    @test size(year_data_df, 1) == 2
    @test year_data_df.year == [2025, 2030]
    @test year_data_df.length == [24, 100]
    @test all(year_data_df.is_milestone .== true)  # ALL functional years are milestone (constraint)

    # This test documents that in the current system:
    # - Commission-only years cannot be used in optimization
    # - All functional years must have profiles
    # - Therefore all functional years are milestone years
    # - Future versions may support default time structures to resolve this constraint
end
