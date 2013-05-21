# Match.jl

Pattern matching as an exercise. This really shouldn't be used right
now. Probably slow as hell.


## Awesome Fizzbuzz
```jl
using Match

function fizzbuzz(range)
    for n=range
        @match (n%3, n%5) {
            (0,0) => print("fizzbuzz "),
            (0,_) => print("fizz "),
            (_,0) => print("buzz "),
             _    => print(string(n, ' '))
        }
    end
end

fizzbuzz(1:15)
# => prints "1 2 fizz 4 buzz fizz 7 8 fizz buzz 11 fizz 13 14 fizzbuzz"
```

## Balancing red-black trees
```jl
using Match

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
    res = @match tree {
      ( Black(z, Red(y, Red(x, a, b), c), d)
      | Black(z, Red(x, a, Red(y, b, c)), d)
      | Black(x, a, Red(z, Red(y, b, c), d))
      | Black(x, a, Red(y, b, Red(z, c, d)))) => (x, y, z, a, b, c, d)
    }

    is(res, nothing) && return tree

    (x, y, z, a, b, c, d) = res
    Red(y, Black(x, a, b), Black(z, c, d))
end

balance(Black(1, Red(2, Red(3, Leaf(), Leaf()), Leaf()), Leaf()))
# => Red(2, Black(3, Leaf(), Leaf()),
#           Black(1, Leaf(), Leaf()))
```
