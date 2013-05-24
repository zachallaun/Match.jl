include("./Unify.jl")

module Match

using Unify
using ExpressionUtils

export @match, @matching, @matchcase

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
        newx, others = buildcase(x)
        vcat!(syms, others)
        newx
    end

    (map(f, v), [Set(syms...)...])
end

buildcase(case)         = (case, {})
buildcase(case::Symbol) = is(case, :_) ? (Anything, {}) : (lvar(case), {case})
function buildcase(case::Expr)
    head = case.head
    if is(head, :call)
        cons, args = case.args[1], case.args[2:end]
        if is(cons, :|)
            arg1, syms1 = buildcase(args[1])
            arg2, syms2 = buildcase(args[2])
            (:(Unify.Either($arg1, $arg2)), [Set(vcat(syms1, syms2)...)...])
        else
            args, syms = walk_and_replace(args)
            (:(TypeCase($(esc(cons)), $(Expr(:vcat, args...)))), syms)
        end
    elseif is(head, :(::))
        ex, typ = case.args
        args, syms = buildcase(ex)
        (:(Unify.Typed($args, $(esc(typ)))), syms)
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

function match(ex, caseblock::Expr)
    cases = filter(ex -> is(ex.head, :->), caseblock.args)
    cases = Expr(:vcat, [funcify_case(case.args...) for case in cases]...)
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

macro match(args...)
    match(args...)
end

macro matching(fn::Expr)
    assert(is(fn.head, :function), "@matching must be given a :function")

    matchbody = fn.args[2]
    fnparams = fn.args[1].args[2:]

    fn.args[1] = map(esc, fn.args[1])

    assert(length(fnparams) > 0, "@matching functions must take at least one parameter")

    matchval = length(fnparams) == 1 ? fnparams[1] : Expr(:tuple, fnparams...)

    fn.args[2] = match(matchval, matchbody)
    fn
end

end # module Match
