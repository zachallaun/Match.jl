using FactCheck
using Match

@facts "Pattern Matching" begin

    @fact "values, wildcards, tuples" begin
        function fizzbuzz(n)
            @match (n%3, n%5) {
                (0,0)=>"fizzbuzz",
                (0,_)=>"fizz",
                (_,0)=>"buzz",
                 _   =>n
            }
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
            @match f {
                Foo(Foo(x, x), Foo(x, x)) => "match: $x",
                _ => "fail"
            }
        end

        nestedallsame(Foo(Foo(1,1),Foo(1,1))) => "match: 1"
        nestedallsame(Foo(Foo(2,1),Foo(1,1))) => "fail"
        nestedallsame(Foo(1,1))               => "fail"
    end

end
