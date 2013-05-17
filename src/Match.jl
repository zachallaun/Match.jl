include("./unify.jl")

module Match

using Unify
using ExpressionUtils

export @match, @matchcase

function vcat!(v1::Vector, v2::Vector)
    for el in v2 push!(v1, el) end
    v1
end

immutable TypeCase{T}
    typ::Type{T}
    fields
end

macro matchcase(T)
    quote
        function Unify._unify(x::TypeCase{$(esc(T))}, y::$(esc(T)), smap)
            for (f1, f2) in zip(x.fields, map(_ -> y.(_), names($(esc(T)))))
                smap = Unify._unify(f1, f2, smap)
                smap == false && return false
            end
            smap
        end
        Unify._unify(x::$(esc(T)), y::TypeCase{$(esc(T))}, smap) =
            Unify._unify(y, x, smap)
    end
end

unifier(case) = (case, {})

# Walks an iterable, recursively digging into Expr args, replacing
#    _   => Anything
#    sym => lvar(sym)
# and building up a list of syms that were turned into lvars.
#
# Returns (walked_array, built_up_syms)
#
function walk_and_replace(v)
    syms = Symbol[]

    function f(x)
        if applicable(buildcase, x)
            newx, others = buildcase(x)
            vcat!(syms, others)
            newx
        else
            x
        end
    end

    (map(f, v), [Set(syms...)...])
end

buildcase(case::Symbol) = is(case, :_) ? (Anything, {}) : (lvar(case), {case})

function buildcase(case::Expr)
    head = case.head
    if is(head, :call)
        cons, args = case.args[1], case.args[2:end]
        args, syms = walk_and_replace(args)
        (:(TypeCase($(esc(cons)), $(Expr(:vcat, args...)))), syms)
    elseif is(head, :tuple)
        args, syms = walk_and_replace(case.args)
        (Expr(:tuple, args...), syms)
    else
        error("Cannot pattern match $(case.head)")
    end
end

immutable NoMatch end

function funcify_case(case, body)
    @gensym smap
    case, bindings = buildcase(case)

    casebody = Expr(:block)
    for binding in bindings
        push!(casebody.args, :($(esc(binding)) = $smap[$(lvar(binding))]))
    end
    push!(casebody.args, esc(body))

    quote
        function (e)
            $smap = Unify.unify($case, e)
            if $smap != false
                $casebody
            else
                NoMatch
            end
        end
    end
end

macro match(ex, cases)
    cases = Expr(:vcat, [funcify_case(case.args...) for case in cases.args[2:]]...)
    quote
        local cases = $cases
        local e = $(esc(ex))
        local val
        for case in cases
            val = case(e)
            is(val, NoMatch) || break
        end
        is(val, NoMatch) ? nothing : val
    end
end

end # module Match

# type Foo
#     a
#     b
#     c
# end
# @matchcase Foo

# f = Foo(rand(1:2), rand(1:2), rand(1:10))

# @match f {
#     Foo(2, 2) => "twos!",
#     Foo(1, x) => "one and $x",
#     Foo(x, 1) => "$x and one"
# }

# @match (n%3, n%5) {
#     (0, 0) => "fizzbuzz",
#     (0, _) => "fizz",
#     (_, 0) => "buzz",
#     (_, _) => n,
# }
