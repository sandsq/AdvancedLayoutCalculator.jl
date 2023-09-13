"""
    AbstractFrequencyHolder
Represents something that holds the frequencies of keycodes.
"""
abstract type AbstractFrequencyHolder end
function holder(h::AbstractFrequencyHolder) error("holder($(typeof(h))) is not defined") end
"""
    getngrams
So we can loop over all ngrams.
"""
function getngrams(h::AbstractFrequencyHolder) error("getngrams($(typeof(h))) is not defined") end
"""
    getuniquekeycodes
Return Vector of all keycodes present in the frequency holder. In other words, every keycode we would possibly need to type should be in here.
"""
function getuniquekeycodes(h::AbstractFrequencyHolder) error("getuniquekeycodes($(typeof(h))) is not defined") end
# """
#     processdocument
# Process a document in accordence to the specified frequency holder.
# """
# function processdocument(h::AbstractFrequencyHolder, docpath::String) error("processdocument not defined for $(typeof(h))") end


function Base.getindex(afh::AbstractFrequencyHolder, kc::Keycode)
    error("You probably meant to use an Ngram($kc) as the key, not the Keycode _$kc.")
end


function _incrementfrequency!(d::Union{Dict{Ngram, Float32}, OrderedDict{Ngram, Float32}}, k::Ngram)
    if k in keys(d)
        d[k] += 1
    else
        d[k] = 1
    end
    return d
end

struct SimpleFrequencyHolder{F <: AbstractFloat} <: AbstractFrequencyHolder
    holder::Dict{Ngram, F}
end
SimpleFrequencyHolder() = SimpleFrequencyHolder(Dict{Ngram, Float32}())
function SimpleFrequencyHolder(io::IO; shiftedsymbols=Commonshiftedsymbols)
    # todo: separate struct for ngrams
    holder = Dict{Ngram, Float32}()
    tempdoc = ""

    doc = read(io, String)
    for c in ProgressBar(doc)
        # tempdoc *= c
        # println(tempdoc)
        kcs = char2keycodes(c; shiftedsymbols=shiftedsymbols)
        if length(kcs) == 0 continue end
        for g in kcs
            if g in shiftedsymbols continue end
            _incrementfrequency!(holder, Ngram(g))
        end
    end

    @info "Setting _BSPS frequency to the average of _SPC and _E."
    holder[Ngram(_BSPC)] = holder[Ngram(_SPC)] + holder[Ngram(_E)]
    close(io)
    return SimpleFrequencyHolder(holder)
end
function SimpleFrequencyHolder(docpath::String; shiftedsymbols=Commonshiftedsymbols)
    if !isfile(docpath) error("$docpath does not exist.") end
    fi = open(docpath, "r")
    fh = SimpleFrequencyHolder(fi; shiftedsymbols=shiftedsymbols)
    close(fi)
    return fh
end
holder(h::SimpleFrequencyHolder) = h.holder
@forward SimpleFrequencyHolder.holder Base.length, Base.getindex, Base.iterate
getngrams(h::SimpleFrequencyHolder) = Set(sort(collect(keys(holder(h)))))
function getuniquekeycodes(h::SimpleFrequencyHolder) 
    return sort(first.(gram.(filter(x -> length(x) == 1, collect(keys(holder(h)))))))
end

const BasicFrequencyTemplate = SimpleFrequencyHolder(Dict{Ngram, Float32}(Ngram(_BSPC) => 30, Ngram(_SPC) => 20, Ngram(_E) => 15, Ngram(_T) => 9.5, Ngram(_A) => 9, Ngram(_O) => 8.9, Ngram(_I) => 8.7, Ngram(_N) => 8.6, Ngram(_S) => 8.4, Ngram(_H) => 8.2, Ngram(_R) => 8, Ngram(_D) => 7.5, Ngram(_L) => 7.3, Ngram(_C) => 7.1, Ngram(_U) => 6.5, Ngram(_SFT) => 6.2, Ngram(_M) => 6, Ngram(_W) => 5.5, Ngram(_ENT) => 5.2, Ngram(_F) => 4.7, Ngram(_G) => 4.3, Ngram(_COMM) => 3.9, Ngram(_Y) => 3.5, Ngram(_P) => 3.2, Ngram(_K) => 3, Ngram(_DOT) => 2.9, Ngram(_B) => 2.8, Ngram(_V) => 2.2, Ngram(_J) => 2, Ngram(_X) => 1.6, Ngram(_Q) => 1.3, Ngram(_Z) => 1))


function _windowgen(vec::Vector{Keycode}, winsize::Int)
    return ((vec[i:i+(winsize-1)]) for i in 1:(length(vec)-winsize+1))
end

function _getsubngrams(s::String; shiftedsymbols=Commonshiftedsymbols)
    strlen = length(s)
    keycodes = string2keycodes(s; shiftedsymbols=shiftedsymbols)
    # println(keycodes)
    n = length(keycodes)

    grams = Ngram[]
    push!(grams, Ngram(keycodes))

    for subn in Iterators.reverse(1:n-1)
        kcseqs = collect(((keycodes[i:i+(subn-1)]) for i in 1:(n-subn+1)))
        for kcseq in kcseqs            
            push!(grams, Ngram(kcseq))
        end
    end
    return filter(x -> length(x) <= strlen, grams)
end

struct Isfilepath end
struct Isstring end

const defaulttopn = [-1, 100, 100, 50, 50]

function _handlespace(g::Ngram)
    spccount = 0
    containsspace = false
    for ele in g
        if ele == _SPC
            containsspace = true
            spccount += 1
        end
    end
    return (length(g) == 2 && spccount >= 2) || spccount >= 3 || (length(g) >= 4 && spccount >= 2)
end

"""
    Ngramconfig
- description:
- maxgrams: go up to this value for ngrams
- topn: topn[i] is the number of i-grams to take (sorted descending by frequency first)
- shiftedsymbols: holds symbols that should be typed with shift+key rather than the specialized keycode. For example, if `shiftedsymbols` contains _EXLM, it will be converted to [_SFT, _1] instead.
- scaletype: how to scale the counts.
    - :ngramlength will treat each ngram size independently and normalize to between 0 and 1
- exclusions: holds symbols that should ignored when calculating ngrams
"""
@kwdef struct Ngramconfig
    description::String = ""
    maxgrams::Int = 4
    topns::Vector{Int} = [-1, 100, 100, 50, 50]
    shiftedsymbols = Commonshiftedsymbols
    scaletype = :ngramlength
    exclusions = Set{Keycode}()
end

mutable struct NgramFrequencyHolder <: AbstractFrequencyHolder
    description::String
    frequencies::Dict{Int, OrderedDict{Ngram, Float32}}
end
"""
    NgramFrequencyHolder
`topn` takes the topn most frequent 2+grams. Unigrams are always taken.
"""
function NgramFrequencyHolder(doc::String, ::Isstring; config = Ngramconfig())

    description = config.description
    maxgrams = config.maxgrams
    topns = config.topns
    shiftedsymbols = config.shiftedsymbols
    scaletype = config.scaletype
    exclusions = config.exclusions

    @info "Bigrams containing space are skipped"

    holder = Dict{Int, OrderedDict{Ngram, Float32}}()
    for n in 1:maxgrams
        holder[n] = OrderedDict{Ngram, Float32}()
    end

    # doc = read(io, String)
    if length(doc) < maxgrams error("Doc should be at least length $maxgrams.") end

    stringinds = collect(eachindex(doc)) # has the actual indicies, which will account for encoding
    initialstring = doc[stringinds[1:maxgrams]]
    initialkeycodes = string2keycodes(initialstring; shiftedsymbols=shiftedsymbols)
    initialkclen = length(initialkeycodes)
    initialgrams = _getsubngrams(initialstring; shiftedsymbols=shiftedsymbols)
    @info "Manually removing runs of spaces. Also not including 3+grams with any space."
    for g in initialgrams
        
        if length(intersect(gram(g), exclusions)) > 0 continue end
        if length(intersect(gram(g), shiftedsymbols)) > 0 continue end
        
        if _handlespace(g) continue end
        _incrementfrequency!(holder[length(g)], g)
    end
    if initialkclen > maxgrams
        initialkeycodes = initialkeycodes[(initialkclen-maxgrams+1):end]
    end
    

    if length(doc) == maxgrams return NgramFrequencyHolder(holder) end
    
    # advance by one letter. then, we only need to count ngrams that are created by adding that letter
    for currentstringind in ProgressBar(stringinds[maxgrams+1:end])
        currentchar = doc[currentstringind]
        currentkeycodes = char2keycodes(currentchar; shiftedsymbols=shiftedsymbols)

        for indtoappend in eachindex(currentkeycodes)
            initialkeycodes = vcat(initialkeycodes[2:end], currentkeycodes[indtoappend])
            for i in 1:maxgrams
                partialkeycodes = initialkeycodes[i:end]
                if (length(partialkeycodes) >= 3) && _SPC in partialkeycodes continue end
                # bunch of really specific grams
                if partialkeycodes == [_W, _H, _A, _L, _E] || partialkeycodes == [_W, _H, _A, _L] || partialkeycodes == [_H, _A, _L, _E] || partialkeycodes == [_D, _A, _R, _C, _Y] || partialkeycodes == [_D, _A, _R, _C] || partialkeycodes == [_A, _R, _C, _Y] || partialkeycodes == [_SFT, _QUOT, _ENT, _ENT] || partialkeycodes == [_DOT, _ENT, _ENT, _SFT] || partialkeycodes == [_DOT, _SFT, _QUOT, _ENT, _ENT] || partialkeycodes == [_ENT, _ENT, _SFT, _QUOT] || partialkeycodes == [_ENT, _ENT, _SFT, _QUOT, _SFT] || partialkeycodes == [_SFT, _QUOT, _ENT, _ENT, _SFT] || partialkeycodes == [_SFT,_E,_L,_I,_Z] || partialkeycodes == [_E,_L,_I,_Z,_A] || partialkeycodes == [_L,_I,_Z,_A,_B] || partialkeycodes == [_I,_Z,_A,_B,_E] || partialkeycodes == [_Z,_A,_B,_E,_T] || partialkeycodes == [_A,_B,_E,_T,_H] || partialkeycodes == [_A, _H, _A, _B] || partialkeycodes == [_SFT, _A, _H, _A, _B] || partialkeycodes == [_QUOT, _ENT, _ENT, _SFT, _QUOT] || partialkeycodes == [_DOT, _ENT, _ENT, _SFT, _QUOT] || partialkeycodes == [_SLSH, _SFT, _QUOT, _ENT, _ENT] || partialkeycodes == [_ENT, _ENT, _SFT] || partialkeycodes == [_DOT, _ENT, _ENT] || partialkeycodes == [_QUOT, _ENT, _ENT] || partialkeycodes == [_L, _L] || partialkeycodes == [_ENT, _SPC, _SPC] continue end
                g = Ngram(partialkeycodes)
                if length(partialkeycodes) >= 2 && allequal(partialkeycodes) continue end
                if length(intersect(gram(g), exclusions)) > 0 continue end
                if length(intersect(gram(g), shiftedsymbols)) > 0 continue end
                
                if _handlespace(g) continue end
                _incrementfrequency!(holder[length(g)], g)
            end
        end
    end
    @info "Setting _BSPS frequency to the average of _SPC and _E."
    holder[1][Ngram(_BSPC)] = (holder[1][Ngram(_SPC)] + holder[1][Ngram(_E)])/2

    for gramlen in 2:maxgrams
        topn = topns[gramlen]
        if topn == -1 break end

        ngramdict = holder[gramlen]
        ngramdict2 = OrderedDict{Ngram, Float32}()
        sort!(ngramdict, byvalue=true, rev=true)
        for (kind, k) in enumerate(keys(ngramdict))
            if kind > topn break end
            ngramdict2[k] = ngramdict[k]
        end
        holder[gramlen] = ngramdict2
    end

    if scaletype == :ngramlength
        for n in keys(holder)
            # if n == 1 continue end
            tot = sum(values(holder[n]))
            # if n == 3 
            #     tot = tot*1.05 
            # elseif n == 4
            #     tot = tot*1.1
            # elseif n == 5
            #     tot = tot*1.15
            # end
            map(x -> holder[n][x] = holder[n][x] / tot, collect(keys(holder[n])))
        end
    end

    return NgramFrequencyHolder(description, holder)
end
# function NgramFrequencyHolder(io::IO; description::String, maxgrams=5, shiftedsymbols=Commonshiftedsymbols, topns=defaulttopn, doscaleperlength=true, exclusions=Set{Keycode}())
#     doc = read(io, String)
#     nfh = NgramFrequencyHolder(doc, Isstring(); description=description, maxgrams=maxgrams, shiftedsymbols=shiftedsymbols, topns=topns, doscaleperlength=doscaleperlength, exclusions=exclusions)
#     close(io)
#     return nfh
# end
function NgramFrequencyHolder(docpath::String; config = Ngramconfig())
    #  description::String="", maxgrams=5, shiftedsymbols=Commonshiftedsymbols, topns=defaulttopn, doscaleperlength=true, exclusions=Set{Keycode}())
    
    description = config.description
    maxgrams = config.maxgrams
    topns = config.topns
    scaletype = config.scaletype

    if !isfile(docpath)
        error("File $docpath does not exist.") 
    end
    
    docpathjld = """$docpath.$(join(topns[2:end], "-"))$(string(scaletype))maxgrams$maxgrams$description.jld2"""
    fh = nothing
    if !isfile(docpathjld)
        fi = open(docpath, "r")
        doc = read(fi, String)

        fh = NgramFrequencyHolder(doc, Isstring(); config=config) 
        # description=description, maxgrams=maxgrams, shiftedsymbols=shiftedsymbols, topns=topns, doscaleperlength=doscaleperlength, exclusions=exclusions)
        
        close(fi)
    @info "Saving $docpathjld"
    jldsave(docpathjld; fh)
    else
        @info "Loading $docpathjld"
        fh = load_object(docpathjld)
    end

    return fh
end
function NgramFrequencyHolder(docpaths::Vector{String}; config=Ngramconfig())
    #  description::String="", maxgrams=5, shiftedsymbols=Commonshiftedsymbols, topns=defaulttopn, doscaleperlength=true, exclusions=Set{Keycode}())
    description = config.description
    maxgrams = config.maxgrams
    topns = config.topns
    shiftedsymbols = config.shiftedsymbols
    scaletype = config.scaletype
    exclusions = config.exclusions

    docstr = ""
    jldpath = ""
    docpre = ""
    for docpath in docpaths
        if !isfile(docpath)
            error("File $docpath does not exist.")
        end
        docstem = split(docpath, "/")[end]
        docpre = join(split(docpath, "/")[1:end-1], "/")
        jldpath *= docstem

        fi = open(docpath, "r")
        docstr *= read(fi, String)
        docstr *= "\n"
        close(fi)
    end
    jldpath = docpre * "/" * jldpath * "$(join(topns[2:end], "-"))$(string(scaletype))maxgrams$maxgrams$description.jld2"

    if !isfile(jldpath)
        fh = NgramFrequencyHolder(docstr, Isstring(); config=config)
        # description=description, maxgrams=maxgrams, shiftedsymbols=shiftedsymbols, topns=topns, doscaleperlength=doscaleperlength, exclusions=exclusions)
        @info "Saving $jldpath"
        jldsave(jldpath; fh)
    else
        @info "Loading $jldpath"
        fh = load_object(jldpath)
    end
    return fh
end
frequencies(h::NgramFrequencyHolder) = h.frequencies
@forward NgramFrequencyHolder.frequencies Base.length, Base.getindex, Base.iterate, Base.keys
function Base.getindex(nfh::NgramFrequencyHolder, ng::Ngram)
    return nfh[length(ng)][ng]
end

"""
    mergefh!
Merges fh2 into fh1
"""
function mergefh!(fh1::NgramFrequencyHolder, fh2::NgramFrequencyHolder, r1::Float32, r2::Float32)
    r1weight = r1 
    r2weight = r2 
    d1 = frequencies(fh1)
    d2 = frequencies(fh2)
    ns = union(keys(d1), keys(d2))
    filledn = false
    for n in ns
        if !(n in keys(d1))
            for g in keys(d2[n])
                d1[n][g] = d2[n][g]
            end
            filledn = true
        end
        if !(n in keys(d2)) continue end # if "n" is not in d2, then it will already be in d1
        if filledn continue end # if fh1 is missing an "n" altogether, just fill it in
        dn1 = d1[n]
        dn2 = d2[n]
        gramset = union(keys(dn1), keys(dn2))
        for gram in gramset
            if !(gram in keys(dn1))
                dn1[gram] = r2weight*dn2[gram]
                continue
            end
            dn1[gram] = r1weight*dn1[gram] + (gram in keys(dn2) ? r2weight*dn2[gram] : 0)
        end
    end
    fh1.frequencies = d1
    return fh1
end

function getngrams(h::NgramFrequencyHolder) 
    d = OrderedDict{Ngram, Float32}()
    # @warn "skipping unigrams so they don't have influence"
    for n in keys(h)
        # if n == 1 continue end
        merge!(d, h[n])
    end
    return keys(d)
end
function getuniquekeycodes(h::NgramFrequencyHolder)
    return only.(gram.(keys(h[1])))
end





