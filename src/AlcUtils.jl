module AlcUtils

using Match
using MacroTools
using Logging


export @forward, @exported_enum, _NO

export KeymapLogLevel, ScoringLogLevel, CounterLogLevel, MutationLogLevel, CrossoverLogLevel, currentdebuglevel,
    char2keycodes,
    string2keycodes,
    Commonshiftedsymbols,
    Commonreplacementexclusions


const ScoringLogLevel = LogLevel(-999)
const CounterLogLevel = LogLevel(-900)
const KeymapLogLevel = LogLevel(-850)
const MutationLogLevel = LogLevel(-800)
const CrossoverLogLevel = LogLevel(-750)
const currentdebuglevel = LogLevel(-600)



"""
@forward Foo.bar f, g, h

`@forward` simply forwards method definition to a given field of a struct.
For example, the above is  equivalent to

```julia
f(x::Foo, args...) = f(x.bar, args...)
g(x::Foo, args...) = g(x.bar, args...)
h(x::Foo, args...) = h(x.bar, args...)
```
"""
macro forward(ex, fs)
    @capture(ex, T_.field_) || error("Syntax: @forward T.x f, g, h")
    T = esc(T)
    fs = isexpr(fs, :tuple) ? map(esc, fs.args) : [esc(fs)]
    :($([:($f(x::$T, args...; kwargs...) =
            (Base.@_inline_meta; $f(x.$field, args...; kwargs...)))
            for f in fs]...);
        nothing)
    end


macro exported_enum(name, args...)
    esc(quote
        @enum($name, $(args...))
        export $name
        $([:(export $arg) for arg in args]...)
        end)
end


@exported_enum Hand left right
@exported_enum Finger pinkie ring middle index thumb
function Base.isless(f1::Finger, f2::Finger)
    if f1 == pinkie 
        if f2 == pinkie return false end
        return true
    end
    if f1 == ring
        if f2 == pinkie || f2 == ring return false end
        return true
    end
    if f1 == middle
        if f2 == pinkie || f2 == ring || f2 == middle return false end
        return true
    end
    if f1 == index
        if f2 == pinkie || f2 == ring || f2 == middle || f2 == index return false end
        return true
    end
    return false
end
Base.:(-)(f1::Finger, f2::Finger) = Int(f1) - Int(f2)


"""
    Keycode
`@enum` to define valid keycodes, e.g., letters, modifiers, etc.

_LS: layer switch
"""
@exported_enum Keycode _A _B _C _D _E _F _G _H _I _J _K _L _M _N _O _P _Q _R _S _T _U _V _W _X _Y _Z _1 _2 _3 _4 _5 _6 _7 _8 _9 _0 _SPC _BSPC _SFT _TAB _LSFT _LCTL _LS _TRNS _ENT _MINS _EQL _LBRC _RBRC _BSLS _SCLN _QUOT _GRV _COMM _DOT _SLSH _TILD _EXLM _AT _HASH _DLR _PERC _CIRC _AMPR _ASTR _LPRN _RPRN _UNDS _PLUS _LCBR _RCBR _PIPE _COLN _DQUO _LT _GT _QUES _ALT _GUI _ESC _F1 _F2 _F3 _F4 _F5 _F6 _F7 _F8 _F9 _F10 _LEFT _UP _DOWN _RGHT _HOME _PGDN _PGUP _END _DEL _PSCR _CAPS _PASS _ø
const _NO = nothing
Base.hash(k::Keycode, h::UInt) = hash((string(k), Int(k)), h)
Base.:(==)(k1::Keycode, k2::Keycode) = hash(k1) == hash(k2)
Base.isless(kc::Keycode, n::Nothing) = return true
Base.isless(n::Nothing, kc::Keycode) = return false
Base.isless(n::Nothing, n2::Nothing) = return false

"""
    Commonshiftedsymbols
These symbols will be typed with shift, so they will not get their own dedicated key.
"""
const Commonshiftedsymbols = Set{Keycode}([_PASS, _EXLM, _AT, _HASH, _DLR, _PERC, _CIRC, _AMPR, _ASTR, _COLN, _UNDS, _QUES, _DQUO, _TILD])
"""
    Commonreplacementexclusions
When performing a replacement point mutation, we do not want these keys to be the replacement. I.e., we only want them to appear once.
"""
const Commonreplacementexclusions = Set{Keycode}([_1, _2, _3, _4, _5, _6, _7, _8, _9, _0, _LPRN, _RPRN, _LBRC, _RBRC, _LCBR, _RCBR])

function kcsymbol2shifted(kc::Keycode; shiftedsymbols=Commonshiftedsymbols)
    if kc in shiftedsymbols
        if kc == _TILD
            return [_SFT, _GRV]
        elseif kc == _EXLM
            return [_SFT, _1]
        elseif kc == _HASH 
            return [_SFT, _3]
        elseif kc == _DLR 
            return [_SFT, _4]
        elseif kc == _PERC 
            return [_SFT, _5]
        elseif kc == _CIRC 
            return [_SFT, _6]
        elseif kc == _AMPR 
            return [_SFT, _7]
        elseif kc == _ASTR 
            return [_SFT, _8]
        elseif kc == _LPRN 
            return [_SFT, _9]
        elseif kc == _RPRN 
            return [_SFT, _0]
        elseif kc == _UNDS 
            return [_SFT, _MINS]
        elseif kc == _PLUS 
            return [_SFT, _EQL]
        elseif kc == _LCBR 
            return [_SFT, _LBRC]
        elseif kc == _RCBR 
            return [_SFT, _RBRC]
        elseif kc == _PIPE 
            return [_SFT, _BSLS]
        elseif kc == _COLN 
            return [_SFT, _SCLN]
        elseif kc == _DQUO 
            return [_SFT, _QUOT]
        elseif kc == _LT 
            return [_SFT, _COMM]
        elseif kc == _GT 
            return [_SFT, _DOT]
        elseif kc == _QUES 
            return [_SFT, _SLSH]
        else
            return kc
        end
    end
    return kc
end

function char2keycodes(c::Char; shiftedsymbols=Commonshiftedsymbols)
    kcs = Vector{Keycode}()
    if isuppercase(c) push!(kcs, _SFT) end
    lowerc = lowercase(c)
    if lowerc in 'a':'z'
        kc = eval(Symbol("_$(uppercase(lowerc))"))
        push!(kcs, kc)
        return kcs
    end
    kc = Match.@match lowerc begin
        '1' => _1
        '2' => _2
        '3' => _3
        '4' => _4
        '5' => _5
        '6' => _6
        '7' => _7
        '8' => _8
        '9' => _9
        '0' => _0
        '-' || '—' => _MINS
        '=' => _EQL
        '[' => _LBRC
        ']' => _RBRC
        '\\' => _BSLS
        ';' => _SCLN
        ''' || '‘' || '’' => _QUOT
        '`' => _GRV
        ',' => _COMM
        '.' => _DOT
        '/' => _SLSH
        '~' => _TILD
        '!' => _EXLM
        '@' => _AT
        '#' => _HASH
        '$' => _DLR
        '%' => _PERC
        '^' => _CIRC
        '&' => _AMPR
        '*' => _ASTR
        '(' => _LPRN
        ')' => _RPRN
        '_' => _UNDS
        '+' => _PLUS
        '{' => _LCBR
        '}' => _RCBR
        '|' => _PIPE
        ':' => _COLN
        '"' || '“' || '”' => _DQUO
        '<' => _LT
        '>' => _GT
        '?' => _QUES
        ' ' => _SPC
        '\n' => _ENT
        'ê' || 'à' || 'é' || '\r' || 'α' || '\ufeff' => _PASS
        _ => begin display(lowerc); @warn "Corresponding keycode not found."; _PASS end
    end
    if kc == _PASS
        return kcs
    end
    kc2 = kcsymbol2shifted(kc; shiftedsymbols=shiftedsymbols)
    
    if kc2 isa Vector
        append!(kcs, kc2)
    else
        push!(kcs, kc)
    end
    return kcs
end

function string2keycodes(s::String; shiftedsymbols=Commonshiftedsymbols)
    keycodes = Vector{Keycode}()
    for c in s
        append!(keycodes, char2keycodes(c; shiftedsymbols=shiftedsymbols))
    end
    return keycodes
end

using Unitful
"""
    u"ku"
Unitful unit for "key size unit" -- designed to mimic the "U" terminology for keycap sizes.
"""
@unit ku "ku" Keysizeunit 13u"mm" false
function __init__()
    Unitful.register(AlcUtils)
end

end # module
