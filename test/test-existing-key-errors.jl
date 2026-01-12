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
