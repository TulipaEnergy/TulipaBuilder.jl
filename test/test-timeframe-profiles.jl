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
