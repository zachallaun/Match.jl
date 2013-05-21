include("../src/Unify.jl")

using FactCheck
using FunctionalCollections
using Unify

@facts "Unification" begin

    @fact "extending substitution maps" begin
        extended(phmap{Any, Any}(), lvar(:x), 10)       => {lvar(:x) => 10}
        extended(phmap{Any, Any}(), lvar(:x), lvar(:y)) => {lvar(:x) => lvar(:y)}
        extended(phmap((lvar(:y), lvar(:x))), lvar(:x), lvar(:y)) => false

        extended(phmap((lvar(:y), 1)), lvar(:x), lvar(:y)) => {lvar(:x) => 1,
                                                               lvar(:y) => 1}
    end

    @fact "simple unification" begin
        unify(lvar(:x), 10)       => {lvar(:x) => 10}
        unify(10,       lvar(:x)) => {lvar(:x) => 10}
        unify(:x,       :x)       => Dict()
        unify(lvar(:x), lvar(:y)) => {lvar(:x) => lvar(:y)}
        unify(1,        2)        => false
    end

    @fact "Iterable unification" begin
        unify(lvar(:x),         [1, 2, 3])    => {lvar(:x) => [1, 2, 3]}
        unify([1, lvar(:x), 3], [1, 2, 3])    => {lvar(:x) => 2}
        unify([1, 2, 3],        [1, 2, 3, 4]) => false

        unify([lvar(:x), lvar(:x)], [1, 2]) => false
        unify([lvar(:x), lvar(:x)], [1, 1]) => {lvar(:x) => 1}

        unify([lvar(:x), 2, 1], [1, 2, lvar(:x)]) => {lvar(:x) => 1}
        unify([lvar(:x), 2, 2], [1, 2, lvar(:x)]) => false

        unify(pvec([lvar(:x), 2, 1]), pvec([1, 2, lvar(:x)])) => {lvar(:x) => 1}
        unify(pvec([lvar(:x), 2, 1]),      [1, 2, lvar(:x)])  => {lvar(:x) => 1}

        unify((1, 2, 3),        (1, 2, 3)) => Dict()
        unify((lvar(:x), 2, 3), (1, 2, 3)) => {lvar(:x) => 1}
    end

    @fact "Expr unification" begin
        local x = :(let $(lvar(:binding))
                        $(lvar(:body))
                    end)
        local y = :(let x=5
                        x+1
                    end)

        unify(x, y) => {lvar(:binding) => :(x=5),
                        lvar(:body)    => :(x+1)}
    end

    @fact "unifying many things!" begin
        unify(lvar(:x), [1, 2], [1, lvar(:y)]) => {lvar(:x) => [1, 2],
                                                   lvar(:y) => 2}

        unify(lvar(:x), [lvar(:y), lvar(:z)], [1, 2, 3]) => false
    end

    @fact "Anything unification" begin
        unify(Anything, [1,2]) => Dict()
    end

    @fact "or" begin
        unify([lvar(:x), lvar(:x)], or([1, 2], [1, 1])) => {lvar(:x) => 1}
        unify(or([1, 2], [1, 1]), [lvar(:x), lvar(:x)]) => {lvar(:x) => 1}
        unify(or([1, 1], [2, 2]), [lvar(:x), lvar(:x)]) => {lvar(:x) => 1}
        unify(or([1, 2], [2, 3]), [lvar(:x), lvar(:x)]) => false
    end

end
