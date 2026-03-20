@testitem "on_conflict for attach_commission_data! on TulipaAsset" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: TulipaAsset, ExistingKeyError

    # first call always inserts regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let asset = TulipaAsset(:a, :producer)
            attach_commission_data!(asset, 2030; on_conflict = mode, capacity = 10.0)
            @test asset.commission_year_data[2030][:capacity] == 10.0
        end
    end

    # :overwrite replaces an existing key
    let asset = TulipaAsset(:a, :producer)
        attach_commission_data!(asset, 2030; capacity = 10.0)
        attach_commission_data!(asset, 2030; on_conflict = :overwrite, capacity = 99.0)
        @test asset.commission_year_data[2030][:capacity] == 99.0
    end

    # :error throws on an existing key and leaves it unchanged
    let asset = TulipaAsset(:a, :producer)
        attach_commission_data!(asset, 2030; capacity = 10.0)
        @test_throws ExistingKeyError attach_commission_data!(
            asset,
            2030;
            on_conflict = :error,
            capacity = 99.0,
        )
        @test asset.commission_year_data[2030][:capacity] == 10.0
    end

    # :skip silently keeps an existing key intact
    let asset = TulipaAsset(:a, :producer)
        attach_commission_data!(asset, 2030; capacity = 10.0)
        attach_commission_data!(asset, 2030; on_conflict = :skip, capacity = 99.0)
        @test asset.commission_year_data[2030][:capacity] == 10.0
    end

    # a new key is always inserted regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let asset = TulipaAsset(:a, :producer)
            attach_commission_data!(asset, 2030; capacity = 10.0)
            attach_commission_data!(asset, 2030; on_conflict = mode, new_key = 1.0)
            @test asset.commission_year_data[2030][:new_key] == 1.0
        end
    end

    # invalid on_conflict value throws ArgumentError
    let asset = TulipaAsset(:a, :producer)
        @test_throws ArgumentError attach_commission_data!(
            asset,
            2030;
            on_conflict = :invalid,
            capacity = 1.0,
        )
    end
end

@testitem "on_conflict for attach_milestone_data! on TulipaAsset" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: TulipaAsset, ExistingKeyError

    # first call always inserts regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let asset = TulipaAsset(:a, :producer)
            attach_milestone_data!(asset, 2030; on_conflict = mode, capacity = 10.0)
            @test asset.milestone_year_data[2030][:capacity] == 10.0
        end
    end

    # :overwrite replaces an existing key
    let asset = TulipaAsset(:a, :producer)
        attach_milestone_data!(asset, 2030; capacity = 10.0)
        attach_milestone_data!(asset, 2030; on_conflict = :overwrite, capacity = 99.0)
        @test asset.milestone_year_data[2030][:capacity] == 99.0
    end

    # :error throws on an existing key and leaves it unchanged
    let asset = TulipaAsset(:a, :producer)
        attach_milestone_data!(asset, 2030; capacity = 10.0)
        @test_throws ExistingKeyError attach_milestone_data!(
            asset,
            2030;
            on_conflict = :error,
            capacity = 99.0,
        )
        @test asset.milestone_year_data[2030][:capacity] == 10.0
    end

    # :skip silently keeps an existing key intact
    let asset = TulipaAsset(:a, :producer)
        attach_milestone_data!(asset, 2030; capacity = 10.0)
        attach_milestone_data!(asset, 2030; on_conflict = :skip, capacity = 99.0)
        @test asset.milestone_year_data[2030][:capacity] == 10.0
    end

    # a new key is always inserted regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let asset = TulipaAsset(:a, :producer)
            attach_milestone_data!(asset, 2030; capacity = 10.0)
            attach_milestone_data!(asset, 2030; on_conflict = mode, new_key = 1.0)
            @test asset.milestone_year_data[2030][:new_key] == 1.0
        end
    end

    # invalid on_conflict value throws ArgumentError
    let asset = TulipaAsset(:a, :producer)
        @test_throws ArgumentError attach_milestone_data!(
            asset,
            2030;
            on_conflict = :invalid,
            capacity = 1.0,
        )
    end
end

@testitem "on_conflict for attach_both_years_data! on TulipaAsset" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: TulipaAsset, ExistingKeyError

    cy, my = 2020, 2030

    # first call always inserts regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let asset = TulipaAsset(:a, :producer)
            attach_both_years_data!(asset, cy, my; on_conflict = mode, capacity = 10.0)
            @test asset.both_years_data[(cy, my)][:capacity] == 10.0
        end
    end

    # :overwrite replaces an existing key
    let asset = TulipaAsset(:a, :producer)
        attach_both_years_data!(asset, cy, my; capacity = 10.0)
        attach_both_years_data!(asset, cy, my; on_conflict = :overwrite, capacity = 99.0)
        @test asset.both_years_data[(cy, my)][:capacity] == 99.0
    end

    # :error throws on an existing key and leaves it unchanged
    let asset = TulipaAsset(:a, :producer)
        attach_both_years_data!(asset, cy, my; capacity = 10.0)
        @test_throws ExistingKeyError attach_both_years_data!(
            asset,
            cy,
            my;
            on_conflict = :error,
            capacity = 99.0,
        )
        @test asset.both_years_data[(cy, my)][:capacity] == 10.0
    end

    # :skip silently keeps an existing key intact
    let asset = TulipaAsset(:a, :producer)
        attach_both_years_data!(asset, cy, my; capacity = 10.0)
        attach_both_years_data!(asset, cy, my; on_conflict = :skip, capacity = 99.0)
        @test asset.both_years_data[(cy, my)][:capacity] == 10.0
    end

    # a new key is always inserted regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let asset = TulipaAsset(:a, :producer)
            attach_both_years_data!(asset, cy, my; capacity = 10.0)
            attach_both_years_data!(asset, cy, my; on_conflict = mode, new_key = 1.0)
            @test asset.both_years_data[(cy, my)][:new_key] == 1.0
        end
    end

    # invalid on_conflict value throws ArgumentError
    let asset = TulipaAsset(:a, :producer)
        @test_throws ArgumentError attach_both_years_data!(
            asset,
            cy,
            my;
            on_conflict = :invalid,
            capacity = 1.0,
        )
    end
end

@testitem "on_conflict for attach_commission_data! on TulipaFlow" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: TulipaFlow, ExistingKeyError

    # first call always inserts regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let flow = TulipaFlow(:a, :b)
            attach_commission_data!(flow, 2030; on_conflict = mode, capacity = 10.0)
            @test flow.commission_year_data[2030][:capacity] == 10.0
        end
    end

    # :overwrite replaces an existing key
    let flow = TulipaFlow(:a, :b)
        attach_commission_data!(flow, 2030; capacity = 10.0)
        attach_commission_data!(flow, 2030; on_conflict = :overwrite, capacity = 99.0)
        @test flow.commission_year_data[2030][:capacity] == 99.0
    end

    # :error throws on an existing key and leaves it unchanged
    let flow = TulipaFlow(:a, :b)
        attach_commission_data!(flow, 2030; capacity = 10.0)
        @test_throws ExistingKeyError attach_commission_data!(
            flow,
            2030;
            on_conflict = :error,
            capacity = 99.0,
        )
        @test flow.commission_year_data[2030][:capacity] == 10.0
    end

    # :skip silently keeps an existing key intact
    let flow = TulipaFlow(:a, :b)
        attach_commission_data!(flow, 2030; capacity = 10.0)
        attach_commission_data!(flow, 2030; on_conflict = :skip, capacity = 99.0)
        @test flow.commission_year_data[2030][:capacity] == 10.0
    end

    # a new key is always inserted regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let flow = TulipaFlow(:a, :b)
            attach_commission_data!(flow, 2030; capacity = 10.0)
            attach_commission_data!(flow, 2030; on_conflict = mode, new_key = 1.0)
            @test flow.commission_year_data[2030][:new_key] == 1.0
        end
    end
end

@testitem "on_conflict for attach_milestone_data! on TulipaFlow" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: TulipaFlow, ExistingKeyError

    # first call always inserts regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let flow = TulipaFlow(:a, :b)
            attach_milestone_data!(flow, 2030; on_conflict = mode, capacity = 10.0)
            @test flow.milestone_year_data[2030][:capacity] == 10.0
        end
    end

    # :overwrite replaces an existing key
    let flow = TulipaFlow(:a, :b)
        attach_milestone_data!(flow, 2030; capacity = 10.0)
        attach_milestone_data!(flow, 2030; on_conflict = :overwrite, capacity = 99.0)
        @test flow.milestone_year_data[2030][:capacity] == 99.0
    end

    # :error throws on an existing key and leaves it unchanged
    let flow = TulipaFlow(:a, :b)
        attach_milestone_data!(flow, 2030; capacity = 10.0)
        @test_throws ExistingKeyError attach_milestone_data!(
            flow,
            2030;
            on_conflict = :error,
            capacity = 99.0,
        )
        @test flow.milestone_year_data[2030][:capacity] == 10.0
    end

    # :skip silently keeps an existing key intact
    let flow = TulipaFlow(:a, :b)
        attach_milestone_data!(flow, 2030; capacity = 10.0)
        attach_milestone_data!(flow, 2030; on_conflict = :skip, capacity = 99.0)
        @test flow.milestone_year_data[2030][:capacity] == 10.0
    end

    # a new key is always inserted regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let flow = TulipaFlow(:a, :b)
            attach_milestone_data!(flow, 2030; capacity = 10.0)
            attach_milestone_data!(flow, 2030; on_conflict = mode, new_key = 1.0)
            @test flow.milestone_year_data[2030][:new_key] == 1.0
        end
    end
end

@testitem "on_conflict for attach_both_years_data! on TulipaFlow" tags = [:unit, :fast] setup =
    [CommonSetup] begin
    using TulipaBuilder: TulipaFlow, ExistingKeyError

    cy, my = 2020, 2030

    # first call always inserts regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let flow = TulipaFlow(:a, :b)
            attach_both_years_data!(flow, cy, my; on_conflict = mode, capacity = 10.0)
            @test flow.both_years_data[(cy, my)][:capacity] == 10.0
        end
    end

    # :overwrite replaces an existing key
    let flow = TulipaFlow(:a, :b)
        attach_both_years_data!(flow, cy, my; capacity = 10.0)
        attach_both_years_data!(flow, cy, my; on_conflict = :overwrite, capacity = 99.0)
        @test flow.both_years_data[(cy, my)][:capacity] == 99.0
    end

    # :error throws on an existing key and leaves it unchanged
    let flow = TulipaFlow(:a, :b)
        attach_both_years_data!(flow, cy, my; capacity = 10.0)
        @test_throws ExistingKeyError attach_both_years_data!(
            flow,
            cy,
            my;
            on_conflict = :error,
            capacity = 99.0,
        )
        @test flow.both_years_data[(cy, my)][:capacity] == 10.0
    end

    # :skip silently keeps an existing key intact
    let flow = TulipaFlow(:a, :b)
        attach_both_years_data!(flow, cy, my; capacity = 10.0)
        attach_both_years_data!(flow, cy, my; on_conflict = :skip, capacity = 99.0)
        @test flow.both_years_data[(cy, my)][:capacity] == 10.0
    end

    # a new key is always inserted regardless of on_conflict mode
    for mode in (:overwrite, :error, :skip)
        let flow = TulipaFlow(:a, :b)
            attach_both_years_data!(flow, cy, my; capacity = 10.0)
            attach_both_years_data!(flow, cy, my; on_conflict = mode, new_key = 1.0)
            @test flow.both_years_data[(cy, my)][:new_key] == 1.0
        end
    end

    # invalid on_conflict value throws ArgumentError
    let flow = TulipaFlow(:a, :b)
        @test_throws ArgumentError attach_both_years_data!(
            flow,
            cy,
            my;
            on_conflict = :invalid,
            capacity = 1.0,
        )
    end
end
