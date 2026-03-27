@testitem "Attach timeframe profile stores data and marks year as milestone" tags =
    [:unit, :fast] setup = [CommonSetup] begin
    tulipa = TulipaData()
    add_asset!(tulipa, "storage", :storage)

    profile_value = collect(1.0:10.0)
    attach_timeframe_profile!(tulipa, "storage", :max_storage_level, 2030, profile_value)

    asset = tulipa.graph["storage"]
    @test haskey(asset.timeframe_profiles, (:max_storage_level, 2030, 1))
    @test asset.timeframe_profiles[(:max_storage_level, 2030, 1)] == profile_value

    # Year is marked as milestone but length is NOT set by attach_timeframe_profile!
    @test haskey(tulipa.years, 2030)
    @test tulipa.years[2030][:is_milestone] == true
    @test !haskey(tulipa.years[2030], :length)
end

@testitem "create_connection populates profiles_timeframe and assets_timeframe_profiles" tags =
    [:unit, :fast, :schema] setup = [CommonSetup, CreateConnectionSetup, TestSchema] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "storage", :storage)
    attach_profile!(tulipa, "storage", :availability, 2030, ones(24))
    attach_timeframe_profile!(tulipa, "storage", :max_storage_level, 2030, 0.9 .* ones(10))
    attach_timeframe_profile!(tulipa, "storage", :min_storage_level, 2030, 0.1 .* ones(10))

    connection = create_connection(tulipa, TestSchema.schema)

    tf_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles_timeframe ORDER BY profile_name, period",
        ) |> DataFrame
    @test size(tf_df, 1) == 20  # 10 periods × 2 profiles
    @test all(tf_df.milestone_year .== 2030)
    @test tf_df.period == repeat(1:10, 2)
    max_rows = filter(r -> occursin("max_storage_level", r.profile_name), tf_df)
    min_rows = filter(r -> occursin("min_storage_level", r.profile_name), tf_df)
    @test all(max_rows.value .≈ 0.9)
    @test all(min_rows.value .≈ 0.1)

    atp_df =
        DuckDB.query(
            connection,
            "SELECT * FROM assets_timeframe_profiles ORDER BY profile_type",
        ) |> DataFrame
    @test size(atp_df, 1) == 2
    @test all(atp_df.asset .== "storage")
    @test all(atp_df.milestone_year .== 2030)
    @test all(atp_df.scenario .== 1)
    @test sort(atp_df.profile_type) == ["max_storage_level", "min_storage_level"]
    # profile_name in assets_timeframe_profiles matches entries in profiles_timeframe
    @test sort(atp_df.profile_name) == sort(unique(tf_df.profile_name))
end

@testitem "Timeframe profiles support multiple scenarios" tags = [:unit, :fast, :schema] setup =
    [CommonSetup, CreateConnectionSetup, TestSchema] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "storage", :storage)
    attach_profile!(tulipa, "storage", :availability, 2030, ones(24))
    attach_timeframe_profile!(
        tulipa,
        "storage",
        :max_storage_level,
        2030,
        0.9 .* ones(5);
        scenario = 1,
    )
    attach_timeframe_profile!(
        tulipa,
        "storage",
        :max_storage_level,
        2030,
        0.8 .* ones(5);
        scenario = 2,
    )

    connection = create_connection(tulipa, TestSchema.schema)

    atp_df =
        DuckDB.query(
            connection,
            "SELECT * FROM assets_timeframe_profiles ORDER BY scenario",
        ) |> DataFrame
    @test size(atp_df, 1) == 2
    @test atp_df.scenario == [1, 2]
    # Each scenario maps to a distinct profile_name
    @test length(unique(atp_df.profile_name)) == 2

    tf_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles_timeframe ORDER BY profile_name, period",
        ) |> DataFrame
    @test size(tf_df, 1) == 10  # 5 periods × 2 distinct profiles
    scenario1_rows = filter(r -> r.profile_name == atp_df.profile_name[1], tf_df)
    scenario2_rows = filter(r -> r.profile_name == atp_df.profile_name[2], tf_df)
    @test all(scenario1_rows.value .≈ 0.9)
    @test all(scenario2_rows.value .≈ 0.8)
end

@testitem "Timeframe profiles across multiple milestone years" tags =
    [:unit, :fast, :schema] setup = [CommonSetup, CreateConnectionSetup, TestSchema] begin
    using DuckDB: DuckDB
    using DataFrames: DataFrame

    tulipa = TulipaData()
    add_asset!(tulipa, "storage", :storage)
    attach_profile!(tulipa, "storage", :availability, 2030, ones(24))
    attach_profile!(tulipa, "storage", :availability, 2040, ones(48))
    attach_timeframe_profile!(tulipa, "storage", :max_storage_level, 2030, 0.9 .* ones(5))
    attach_timeframe_profile!(tulipa, "storage", :max_storage_level, 2040, 0.7 .* ones(8))

    connection = create_connection(tulipa, TestSchema.schema)

    atp_df =
        DuckDB.query(
            connection,
            "SELECT * FROM assets_timeframe_profiles ORDER BY milestone_year",
        ) |> DataFrame
    @test size(atp_df, 1) == 2
    @test atp_df.milestone_year == [2030, 2040]
    @test all(atp_df.asset .== "storage")

    tf_df =
        DuckDB.query(
            connection,
            "SELECT * FROM profiles_timeframe ORDER BY milestone_year, period",
        ) |> DataFrame
    @test size(tf_df, 1) == 13  # 5 periods (2030) + 8 periods (2040)
    rows_2030 = filter(r -> r.milestone_year == 2030, tf_df)
    rows_2040 = filter(r -> r.milestone_year == 2040, tf_df)
    @test size(rows_2030, 1) == 5
    @test size(rows_2040, 1) == 8
    @test all(rows_2030.value .≈ 0.9)
    @test all(rows_2040.value .≈ 0.7)
end
