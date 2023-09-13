module TextProcessor

using OrderedCollections
using AdvancedLayoutCalculator.AlcUtils
using Match
using ProgressBars
using JLD2

export
    Ngram,
    gram,
    ngram2string,
    @ngram_str,

    AbstractFrequencyHolder,
    KeycodeFrequencyHolder,
    SimpleFrequencyHolder,
    BasicFrequencyTemplate,
    holder,
    getngrams,
    getuniquekeycodes,
    Commonshiftedsymbols,

    Isfilepath,
    Isstring,
    Ngramconfig,
    NgramFrequencyHolder,
    frequencies,
    mergefh!

include("ngrams.jl")
include("frequencyholder.jl")

end # module