# test/test_sweep.jl — Parameter sweep tests

using DataFrames

@testset "Parameter Sweep" begin

    @testset "tilt profiles" begin
        # Single rotor: all profiles return same tilt
        @test CoaxialAutogyroStacking.uniform_tilt(1) == [10.0]
        @test CoaxialAutogyroStacking.top_draggy_tilt(1) == [10.0]
        @test CoaxialAutogyroStacking.bottom_lifty_tilt(1) == [10.0]
        @test CoaxialAutogyroStacking.graded_tilt(1) == [10.0]

        # Multi-rotor: profiles are length N
        for N in [2, 3, 4]
            @test length(CoaxialAutogyroStacking.uniform_tilt(N)) == N
            @test length(CoaxialAutogyroStacking.top_draggy_tilt(N)) == N
            @test length(CoaxialAutogyroStacking.bottom_lifty_tilt(N)) == N
            @test length(CoaxialAutogyroStacking.graded_tilt(N)) == N
        end

        # All tilts within physical range
        for N in [1, 2, 3, 4]
            for profile in [CoaxialAutogyroStacking.uniform_tilt,
                             CoaxialAutogyroStacking.top_draggy_tilt,
                             CoaxialAutogyroStacking.bottom_lifty_tilt,
                             CoaxialAutogyroStacking.graded_tilt]
                tilts = profile(N)
                @test all(0.0 .<= tilts .<= 30.0)
            end
        end

        # top_draggy: tilt decreases from top to bottom
        td = CoaxialAutogyroStacking.top_draggy_tilt(4)
        @test td[1] > td[2] > td[3] > td[4]

        # bottom_lifty: tilt increases from top to bottom
        bl = CoaxialAutogyroStacking.bottom_lifty_tilt(4)
        @test bl[1] < bl[2] < bl[3] < bl[4]
    end

    @testset "parameter_sweep — smoke test" begin
        df = CoaxialAutogyroStacking.parameter_sweep(
            radii=[1.0, 2.0],
            stack_counts=[1, 3],
            spacings=[10.0],
            profiles=["uniform", "graded"],
            wind_speeds=[6.0, 8.0, 10.0],
            elevations=[55.0],
        )

        # Expected rows: 2 × 2 × 1 × 2 × 3 × 1 = 24
        @test nrow(df) == 24

        # Check column names
        expected_cols = ["radius", "n_rotors", "spacing", "profile", "elevation",
                         "wind_speed", "anchor_tension", "total_lift",
                         "profile_min", "profile_max"]
        for col in expected_cols
            @test col in names(df)
        end

        # Tension increases with wind speed for any single config
        sub = df[(df.radius .== 2.0) .& (df.n_rotors .== 3) .&
                 (df.profile .== "uniform"), :]
        sorted = sort(sub, :wind_speed)
        @test all(diff(sorted.anchor_tension) .> 0)

        # More rotors → more tension (at same radius and wind)
        r1 = df[(df.radius .== 2.0) .& (df.n_rotors .== 1) .&
                (df.wind_speed .== 8.0) .& (df.profile .== "uniform"), :].anchor_tension[1]
        r3 = df[(df.radius .== 2.0) .& (df.n_rotors .== 3) .&
                (df.wind_speed .== 8.0) .& (df.profile .== "uniform"), :].anchor_tension[1]
        @test r3 > r1

        # profile_min < profile_max (tension increases downward)
        @test all(df.profile_min .< df.profile_max)

        # Non-negative tensions at positive wind
        @test all(df.anchor_tension .>= 0.0)
    end

    @testset "viability columns — tip_speed & tip_reynolds" begin
        df = CoaxialAutogyroStacking.parameter_sweep(
            radii=[1.0],
            stack_counts=[1, 3],
            spacings=[10.0],
            profiles=["uniform", "graded"],
            wind_speeds=[6.0, 12.0],
            elevations=[55.0],
        )

        # Phase 8.5 Tasks 3-4: every sweep row carries viability numbers
        @test "tip_speed" in names(df)
        @test "tip_reynolds" in names(df)

        # Physically meaningful: both strictly positive at positive wind
        @test all(df.tip_speed .> 0.0)
        @test all(df.tip_reynolds .> 0.0)

        # Constant tip-speed-ratio model: doubling wind doubles tip speed
        lo = df[(df.wind_speed .== 6.0) .& (df.n_rotors .== 1) .&
                (df.profile .== "uniform"), :].tip_speed[1]
        hi = df[(df.wind_speed .== 12.0) .& (df.n_rotors .== 1) .&
                (df.profile .== "uniform"), :].tip_speed[1]
        @test hi ≈ 2.0 * lo rtol = 1e-6

        # Consistency: for a single-rotor stack the reported Re must be the
        # Re of that same rotor, i.e. Re = rho * v_tip * chord / mu
        row = df[(df.wind_speed .== 6.0) .& (df.n_rotors .== 1) .&
                 (df.profile .== "uniform"), :]
        re_expected = 1.225 * row.tip_speed[1] * 0.15 / 1.81e-5
        @test row.tip_reynolds[1] ≈ re_expected rtol = 1e-6

        # Worst-case semantics on a mixed-tilt stack (graded, 3 rotors):
        # reported tip_speed is the max across rotors, tip_reynolds the min —
        # so tip_reynolds must NOT exceed the Re implied by max tip speed
        g = df[(df.wind_speed .== 6.0) .& (df.n_rotors .== 3) .&
               (df.profile .== "graded"), :]
        re_from_max_tip = 1.225 * g.tip_speed[1] * 0.15 / 1.81e-5
        @test g.tip_reynolds[1] <= re_from_max_tip + 1e-9
    end

    @testset "compute_figures_of_merit" begin
        df = CoaxialAutogyroStacking.parameter_sweep(
            radii=[1.5],
            stack_counts=[2],
            spacings=[10.0],
            profiles=["uniform"],
            wind_speeds=[4.0, 8.0, 12.0],
            elevations=[55.0],
        )

        fom = CoaxialAutogyroStacking.compute_figures_of_merit(df)
        @test nrow(fom) == 1  # one unique config

        # CV should be between 0 and some reasonable upper bound
        @test fom.tension_cv[1] >= 0.0
        @test fom.tension_cv[1] < 2.0  # shouldn't be wildly unstable

        # N/kg is positive
        @test fom.tension_per_kg[1] > 0.0

        # Mean tension within min/max range
        @test fom.min_tension[1] <= fom.mean_anchor_tension[1] <= fom.max_tension[1]
    end

    @testset "pareto_front" begin
        # Create a simple dataset with known Pareto front
        df = DataFrame(
            x = [1.0, 2.0, 2.0, 3.0, 1.5],
            y = [3.0, 2.0, 1.0, 1.0, 1.5],
        )

        # Maximise both → Pareto should be (1,3), (2,2), (3,1)
        pf = CoaxialAutogyroStacking.pareto_front(df, :x, :y)
        @test nrow(pf) == 3
        @test (1.0, 3.0) in zip(pf.x, pf.y)
        @test (2.0, 2.0) in zip(pf.x, pf.y)
        @test (3.0, 1.0) in zip(pf.x, pf.y)

        # Minimise y, maximise x → Pareto includes (3,1), (2,2), possibly (1,3) — check dominance
        pf2 = CoaxialAutogyroStacking.pareto_front(df, :x, :y, sense=(:max, :min))
        @test nrow(pf2) >= 1
        @test (3.0, 1.0) in zip(pf2.x, pf2.y)  # best: highest x, lowest y
    end
end
