using FactCheck
using Match

@facts "Pattern Matching" begin

    @fact "literal values" begin
        (@match 1 begin
            3 -> "three"
            2 -> "two"
            1 -> "one"
         end) => "one"
    end

    @fact "values, wildcards, tuples" begin
        function fizzbuzz(n)
            @match (n%3, n%5) begin
                (0,0) -> "fizzbuzz"
                (0,_) -> "fizz"
                (_,0) -> "buzz"
                (_,_) -> n
            end
        end

        fizzbuzz(15) => "fizzbuzz"
        fizzbuzz(3)  => "fizz"
        fizzbuzz(5)  => "buzz"
        fizzbuzz(4)  => 4
    end

    @fact "matching on type" begin
        function sillytype(x)
            @match x begin
                x::Int     -> Int
                x::Float64 -> Float64
                x::Char    -> Char
                _          -> "no clue"
            end
        end

        sillytype(1)   => Int
        sillytype(1.0) => Float64
        sillytype('1') => Char
        sillytype("1") => "no clue"

        function samewithtype(tup)
            @match tup begin
                (x, x)::(Float64, Float64) -> :a
                (x, x)::(Int    , Float64) -> :b
                (x, x)::(Float64, Int    ) -> :c
                (x, x)::(Int    , Int    ) -> :d
            end
        end

        samewithtype((1.0, 1.0)) => :a
        samewithtype((1, 1.0))   => :b
        samewithtype((1.0, 1))   => :c
        samewithtype((1, 1))     => :d
        samewithtype((1, 2))     => nothing
    end

    @fact "matchcases, nesting, binding" begin
        type Foo
            a
            b
        end
        @matchcase Foo

        function nestedallsame(f)
            @match f begin
                Foo(Foo(x, x), Foo(x, x)) -> "match: $x"
                _ -> "fail"
            end
        end

        nestedallsame(Foo(Foo(1,1),Foo(1,1))) => "match: 1"
        nestedallsame(Foo(Foo(2,1),Foo(1,1))) => "fail"
        nestedallsame(Foo(1,1))               => "fail"
    end

    @fact "or" begin
        abstract RBTree

        immutable Leaf <: RBTree
        end

        immutable Red <: RBTree
            value
            left::RBTree
            right::RBTree
        end
        @matchcase Red

        immutable Black <: RBTree
            value
            left::RBTree
            right::RBTree
        end
        @matchcase Black

        function balance(tree::RBTree)
            res = @match tree begin
              ( Black(z, Red(y, Red(x, a, b), c), d)
              | Black(z, Red(x, a, Red(y, b, c)), d)
              | Black(x, a, Red(z, Red(y, b, c), d))
              | Black(x, a, Red(y, b, Red(z, c, d)))) -> (x, y, z, a, b, c, d)
            end

            is(res, nothing) && return tree

            (x, y, z, a, b, c, d) = res
            Red(y, Black(x, a, b), Black(z, c, d))
        end

        (balance(Black(1, Red(2, Red(3, Leaf(), Leaf()), Leaf()), Leaf()))
         => Red(2, Black(3, Leaf(), Leaf()), Black(1, Leaf(), Leaf())))
    end

    # @fact "@matching functions" begin
    #     @matching function map(f::Function, l::List)
    #         (f, _::EmptyList) -> EmptyList()
    #         (f, x..rest)      -> f(x)..map(f, rest)
    #     end

    #     @matching function secd(s, e, c, d)
    #         (s, e, _::LDC..x..c, d) -> (x..s, e, c, d)
    #         ......
    #     end
    # end

end
