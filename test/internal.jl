@testset "Internal utility functions" begin
    @testset "_generators_by_reserve_zone" begin
        zone_gens = FNM._generators_by_reserve_zone(TEST_SYSTEM)
        @test zone_gens isa Dict
        @test zone_gens[1] == [3]
        @test zone_gens[2] == [7]
        @test issetequal(zone_gens[FNM.MARKET_WIDE_ZONE], [3, 7])
        @test FNM._get_resolution_in_minutes(TEST_SYSTEM) == 60
    end
    @testset "_add_to_objective!" begin
        model = Model(GLPK.Optimizer)
        @variable(model, x[1:5] >= 0)
        @objective(model, Min, sum(x))
        expr = 2 * x[3]
        FNM._add_to_objective!(model, expr)
        @test objective_function(model) == sum(x) + expr
    end
    @testset "_variable_cost" begin
        system = fake_3bus_system(MISO, DA; n_periods=2)
        fnm = unit_commitment(system, GLPK.Optimizer)
        unit_codes = get_unit_codes(ThermalGen, fnm.system)
        n_periods = get_forecast_horizon(fnm.system)
        offer_curves = get_offer_curves(fnm.system)
        Λ, block_lims, n_blocks = FNM._curve_properties(offer_curves, n_periods)
        thermal_cost = FNM._variable_cost(
            fnm.model, unit_codes, n_periods, n_blocks, Λ, :p, 1
        )
        p_aux = fnm.model[:p_aux]
        # Generators 3 and 7 have offer curves with prices and [600, 800, 825]
        # [400, 600, 625], respectively.
        # https://gitlab.invenia.ca/invenia/research/FullNetworkDataPrep.jl/-/blob/master/src/testutils.jl#L122
        @test thermal_cost ==
            600 * p_aux[3, 1, 1] + 800 * p_aux[3, 1, 2] + 825 * p_aux[3, 1, 3] +
            600 * p_aux[3, 2, 1] + 800 * p_aux[3, 2, 2] + 825 * p_aux[3, 2, 3] +
            400 * p_aux[7, 1, 1] + 600 * p_aux[7, 1, 2] + 625 * p_aux[7, 1, 3] +
            400 * p_aux[7, 2, 1] + 600 * p_aux[7, 2, 2] + 625 * p_aux[7, 2, 3]
    end
end
