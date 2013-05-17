module Unify

using FunctionalCollections

export unify, extended, lvar, Anything

const _LogicVarKey = 0x1f75f6e80ac3828f

immutable LogicVar
    name
end
lvar = LogicVar
Base.isequal(v1::LogicVar, v2::LogicVar) = isequal(v1.name, v2.name)
Base.hash(v::LogicVar) = bitmix(_LogicVarKey, hash(v.name))
Base.show(io::IO, v::LogicVar) = print(io, string(v.name))

# Extend the substitution map "blindly"
#
extended_nocheck(smap::phmap, v::LogicVar, val) = assoc(smap, v, val)

# Check for circular references before extending the substitution map.
# Returns `false` if a circular reference exists.
#
extended(smap::phmap, v::LogicVar, val) = extended_nocheck(smap, v, val)
function extended(smap::phmap, v::LogicVar, val::LogicVar)
    if haskey(smap, val)
        atval = smap[val]
        atval != v || return false # circular reference
        extended(smap, v, atval)
    else
        extended_nocheck(smap, v, val)
    end
end

empty_smap = phmap{LogicVar, Any}()

unify(x, y) = _unify(x, y, empty_smap)
function unify(x, xs...)
    function reducer(acc, y)
        smap, x = acc
        (_unify(x, y, smap), y)
    end
    reduce(reducer, (empty_smap, x), xs)[1]
end

_unify(x::LogicVar, y::LogicVar, smap) =
    let ext = extended(smap, x, y)
        ext == false || return ext
        extended(smap, y, x)
    end

_unify(x, y::LogicVar, smap) = _unify(y, x, smap)
function _unify(x::LogicVar, y, smap)
    if haskey(smap, x)
        smap[x] == y || return false
        smap
    else
        extended(smap, x, y)
    end
end

_unify(x, y, smap) = x == y && return smap

function _unify_iterable(x, y, smap)
    length(x) == length(y) || return false
    for (xel, yel) in zip(x, y)
        smap = _unify(xel, yel, smap)
        smap == false && return false
    end
    smap
end
_unify(x::AbstractArray, y::AbstractArray, smap) = _unify_iterable(x, y, smap)
_unify(x::Tuple, y::Tuple, smap) = _unify_iterable(x, y, smap)

_unify(x::Expr, y::Expr, smap) =
    x.head == y.head && return (x.head == :line ? # ignore line annotations
                                smap :
                                _unify(x.args, y.args, smap))

immutable Anything end
_unify(::Type{Anything}, ::Type{Anything}, smap) = smap
_unify(::Type{Anything}, ::LogicVar      , smap) = smap
_unify(::Type{Anything}, _               , smap) = smap
_unify(::LogicVar,       ::Type{Anything}, smap) = smap
_unify(_,                ::Type{Anything}, smap) = smap

end # module Unify
