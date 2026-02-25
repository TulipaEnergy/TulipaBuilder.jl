@testsnippet ExportSetup begin
    function read_csv_folder_into_df(path)
        data = Dict{Symbol,DataFrame}()
        for file in readdir(path, join = true)
            key = Symbol(splitext(basename(file))[1])
            data[key] = DataFrame(CSV.File(file))
        end

        return data
    end

    function create_and_get_data(tulipa; cluster = false, populate_with_defaults = false)
        connection = create_connection(tulipa)
        if cluster
            TC.dummy_cluster!(connection)
        end
        if populate_with_defaults
            TEM.populate_with_defaults!(connection)
        end

        tmpdir = mktempdir()
        create_case_study_csv_folder(connection, tmpdir)
        folder_data = read_csv_folder_into_df(tmpdir)

        return folder_data
    end

    function manual_empty_data()
        data = Dict(
            :asset => DataFrame(asset = String[], type = String[]),
            :asset_both => DataFrame(
                asset = String[],
                commission_year = Int[],
                milestone_year = Int[],
            ),
            :asset_commission => DataFrame(asset = String[], commission_year = Int[]),
            :asset_milestone => DataFrame(asset = String[], milestone_year = Int[]),
            :assets_profiles => DataFrame(
                asset = String[],
                commission_year = Int[],
                profile_name = String[],
                profile_type = String[],
            ),
            :flow => DataFrame(from_asset = String[], to_asset = String[]),
            :flow_both => DataFrame(
                from_asset = String[],
                to_asset = String[],
                commission_year = Int[],
                milestone_year = Int[],
            ),
            :flow_commission => DataFrame(
                from_asset = String[],
                to_asset = String[],
                commission_year = Int[],
            ),
            :flow_milestone => DataFrame(
                from_asset = String[],
                to_asset = String[],
                milestone_year = Int[],
            ),
            :profiles => DataFrame(
                profile_name = String[],
                year = Int[],
                scenario = Int[],
                timestep = Int[],
                value = Float64[],
            ),
            :year_data =>
                DataFrame(year = Int[], length = Int[], is_milestone = Bool[]),
        )

        return data
    end

    function test_that_both_have_the_same_tables(data, manual_data)
        @test sort(collect(keys(data))) == sort(collect(keys(manual_data)))
    end

    function test_that_both_have_the_same_columns(data, manual_data)
        for (key, table) in data
            @test sort(collect(names(table))) == sort(collect(names(manual_data[key])))
        end
    end

    function test_that_both_have_the_same_data(data, manual_data) # should ignore types
        for (key, table) in data
            for col in names(table)
                data_values = table[:, col]
                manual_data_values = manual_data[key][:, col]
                @test data_values == manual_data_values
            end
        end
    end

    function test_that_tables_are_equivalent(data, manual_data)
        test_that_both_have_the_same_tables(data, manual_data)
        test_that_both_have_the_same_columns(data, manual_data)
        test_that_both_have_the_same_data(data, manual_data)
    end
end

@testitem "Test exporting empty problem to case study" tags = [:export] setup =
    [CommonSetup, ExportSetup] begin
    tulipa = TulipaData{String}()

    manual_data = manual_empty_data()
    data = create_and_get_data(tulipa)
    test_that_tables_are_equivalent(data, manual_data)
end

@testitem "Test exporting basic problem to case study - multiple stages" tags = [:export] setup =
    [CommonSetup, ExportSetup] begin
    tulipa = TulipaData{String}()

    ## Stage 1 - 1 asset (some columns are ignored)

    add_asset!(
        tulipa,
        "ccgt",
        :producer,
        capacity = 2.0,
        investment_method = "simple",
        investable = true, # ignored until an year is introduced
        investment_cost = 3.0, # ignored until an year is introduced
    )

    manual_data = manual_empty_data()

    manual_data[:asset].capacity = Float64[]
    manual_data[:asset].investment_method = String[]
    # notice that it is all string because of the conversion to CSV and back
    push!(manual_data[:asset], ("ccgt", "producer", 2.0, "simple"))

    data = create_and_get_data(tulipa)
    test_that_tables_are_equivalent(data, manual_data)

    ## Stage 2 - attach profile columns are picked up)

    ccgt_profile = rand(0.1:0.1:0.9, 24)
    attach_profile!(tulipa, "ccgt", :availability, 2030, ccgt_profile)

    manual_data[:asset_commission].investment_cost = Float64[] # investable is lost because there is
    push!(manual_data[:asset_commission], ("ccgt", 2030, 3.0))
    manual_data[:asset_milestone].investable = Bool[] # investable is lost because there is
    push!(manual_data[:asset_milestone], ("ccgt", 2030, true))
    push!(manual_data[:asset_both], ("ccgt", 2030, 2030)) # ERROR: Shouldn't be here (I think)
    push!(
        manual_data[:assets_profiles],
        ("ccgt", 2030, "ccgt-availability-2030", "availability"),
    )
    for (i, x) in enumerate(ccgt_profile)
        push!(manual_data[:profiles], ("ccgt-availability-2030", 2030, 1, i, x))
    end

    push!(manual_data[:year_data], (2030, 24, 1.0))

    data = create_and_get_data(tulipa)
    test_that_tables_are_equivalent(data, manual_data)

    ## Stage 3 - another asset and a flow

    add_asset!(tulipa, "Hub", :hub)
    add_flow!(tulipa, "ccgt", "Hub", operational_cost = 4.0)

    push!(manual_data[:asset], ("Hub", "hub", 0.0, "none"))
    push!(manual_data[:asset_commission], ("Hub", 2030, 0.0))
    push!(manual_data[:asset_milestone], ("Hub", 2030, false))
    push!(manual_data[:asset_both], ("Hub", 2030, 2030))
    push!(manual_data[:flow], ("ccgt", "Hub"))
    push!(manual_data[:flow_commission], ("ccgt", "Hub", 2030))
    manual_data[:flow_milestone].operational_cost = Float64[]
    push!(manual_data[:flow_milestone], ("ccgt", "Hub", 2030, 4.0))
    # push!(manual_data[:flow_both], ("ccgt", "Hub", 2030, 2030)) # ERROR: Should this be here?

    data = create_and_get_data(tulipa)
    test_that_tables_are_equivalent(data, manual_data)
end
