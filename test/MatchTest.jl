using FactCheck
using Match

@facts "Pattern Matching" begin

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

end
