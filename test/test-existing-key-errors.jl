@testitem "ExistingKeyError is thrown for duplicate keys" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()

    add_asset!(tulipa, "producer", :producer)
    @test_throws ExistingKeyError add_asset!(tulipa, "producer", :producer)
    add_asset!(tulipa, "consumer", :consumer)
    add_flow!(tulipa, "producer", "consumer")
    @test_throws ExistingKeyError add_flow!(tulipa, "producer", "consumer")
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24))
    @test_throws ExistingKeyError attach_profile!(
        tulipa,
        "producer",
        :availability,
        2030,
        ones(24),
    )
    attach_profile!(tulipa, "producer", "consumer", :inflows, 2030, ones(24))
    @test_throws ExistingKeyError attach_profile!(
        tulipa,
        "producer",
        "consumer",
        :inflows,
        2030,
        ones(24),
    )
    add_asset_group!(tulipa, "group", 2030)
    @test_throws ExistingKeyError add_asset_group!(tulipa, "group", 2030)
    set_partition!(tulipa, "producer", 2030, 1, 3)
    @test_throws ExistingKeyError set_partition!(tulipa, "producer", 2030, 1, 3)
    set_partition!(tulipa, "producer", "consumer", 2030, 1, 3)
    @test_throws ExistingKeyError set_partition!(tulipa, "producer", "consumer", 2030, 1, 3)
end

@testitem "ExistingKeyError for duplicate scenario profiles" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: ExistingKeyError

    tulipa = TulipaData()
    add_asset!(tulipa, "producer", :producer)

    # Attach scenario profile
    attach_profile!(tulipa, "producer", :availability, 2030, ones(24); scenario = 1)

    # Try to attach the same scenario profile again
    @test_throws ExistingKeyError attach_profile!(
        tulipa,
        "producer",
        :availability,
        2030,
        ones(24);
        scenario = 1,
    )

    # But we can attach a different scenario
    attach_profile!(tulipa, "producer", :availability, 2030, 2 .* ones(24); scenario = 2)
    # And we can attach a non-scenario profile with the same profile_type and year (default scenario assigned)
    attach_profile!(tulipa, "producer", :demand, 2030, ones(24))
end
