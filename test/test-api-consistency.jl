@testitem "TulipaData in-place functions return tulipa" tags = [:unit, :fast, :api] begin
    using TulipaBuilder

    tulipa = TulipaData()

    # add_* functions
    @test add_or_update_year!(tulipa, 2030) === tulipa
    @test add_asset!(tulipa, "producer1", :producer) === tulipa
    @test add_asset!(tulipa, "consumer1", :consumer) === tulipa
    @test add_flow!(tulipa, "producer1", "consumer1") === tulipa
    @test add_asset_group!(tulipa, "group1", 2030) === tulipa

    # attach_* functions (asset variants)
    @test attach_commission_data!(tulipa, "producer1", 2030) === tulipa
    @test attach_milestone_data!(tulipa, "producer1", 2030) === tulipa
    @test attach_both_years_data!(tulipa, "producer1", 2030, 2030) === tulipa
    @test attach_profile!(tulipa, "producer1", :availability, 2030, rand(24)) === tulipa

    # attach_* functions (flow variants)
    @test attach_commission_data!(tulipa, "producer1", "consumer1", 2030) === tulipa
    @test attach_milestone_data!(tulipa, "producer1", "consumer1", 2030) === tulipa
    @test attach_both_years_data!(tulipa, "producer1", "consumer1", 2030, 2030) === tulipa

    # set_partition functions
    @test set_partition!(tulipa, "producer1", 2030, 1, 3) === tulipa
    @test set_partition!(tulipa, "producer1", 2030, 2, :math, "4x6") === tulipa
    @test set_partition!(tulipa, "producer1", "consumer1", 2030, 1, 3) === tulipa
    @test set_partition!(tulipa, "producer1", "consumer1", 2030, 2, :math, "4x6") === tulipa
end

@testitem "TulipaAsset in-place functions return asset" tags = [:unit, :fast, :api] begin
    using TulipaBuilder:
        TulipaAsset,
        attach_commission_data!,
        attach_milestone_data!,
        attach_both_years_data!,
        attach_profile!

    asset = TulipaAsset("test", :producer)

    @test attach_commission_data!(asset, 2030, capacity = 1.0) === asset
    @test attach_milestone_data!(asset, 2030, investable = true) === asset
    @test attach_both_years_data!(asset, 2030, 2030, initial_units = 1) === asset
    @test attach_profile!(asset, :availability, 2030, rand(24)) === asset
    @test set_partition!(asset, 2030, 3, 4) === asset
    @test set_partition!(asset, 2030, 4, :explicit, "12;12") === asset
end

@testitem "TulipaFlow in-place functions return flow" tags = [:unit, :fast, :api] begin
    using TulipaBuilder:
        TulipaFlow, attach_commission_data!, attach_milestone_data!, attach_both_years_data!

    flow = TulipaFlow("from", "to")

    @test attach_commission_data!(flow, 2030, capacity = 1.0) === flow
    @test attach_milestone_data!(flow, 2030, is_transport = false) === flow
    @test attach_both_years_data!(flow, 2030, 2030, efficiency = 1.0) === flow
    @test attach_profile!(flow, :inflows, 2030, rand(24)) === flow
    @test set_partition!(flow, 2030, 3, 4) === flow
    @test set_partition!(flow, 2030, 4, :explicit, "12;12") === flow
end

@testitem "API consistency for scenario attach_profile!" tags = [:unit, :fast, :api] begin
    using TulipaBuilder: ExistingKeyError
    # Test that attach_profile! returns the tulipa object for chaining
    tulipa = TulipaData()
    add_asset!(tulipa, "producer1", :producer)

    @test attach_profile!(
        tulipa,
        "producer1",
        :availability,
        2030,
        rand(24);
        scenario = 1,
    ) === tulipa

    # Test that attach_profile! returns the asset object
    asset = tulipa.graph["producer1"]
    @test attach_profile!(asset, :availability, 2031, rand(24); scenario = 1) === asset

end
