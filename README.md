# AdvancedLayoutCalculator

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://sandsquaretech.github.io/AdvancedLayoutCalculator.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://sandsquaretech.github.io/AdvancedLayoutCalculator.jl/dev/)
[![Build Status](https://github.com/sandsquaretech/AdvancedLayoutCalculator.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/sandsquaretech/AdvancedLayoutCalculator.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/sandsquaretech/AdvancedLayoutCalculator.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/sandsquaretech/AdvancedLayoutCalculator.jl)

AdvancedLayoutCalculator, or ALC (like alchemist), is designed to generate a (reasonably) optimal keyboard layout given some text, a keyboard layout, and key position-based weights. An important distinction from other layout optimizers is the ability to consider "shift" as its own separate key -- fast typing involves rolling "shift" + alpha to obtain the capital version, meaning "shift" should be optimized for. Additionally, we want to account for other custom firmware features like layers.

## Will an optimized layout make me a faster typist?

Probably not. If you have poor typing form, you may benefit from relearning due to a new layout, but it is unlikely speedup will come from the layout itself. 

I have a theory as to why this is. Now, it is the case that an optimized layout requires overall less finger travel. So asssuming the same finger speeds and accelerations between different layouts, we would expect that typing a sequence requires less time on an optimized layout. However, since we type with multiple fingers at a time, we probably pre-move fingers -- when typing a common pattern such as "the" for example, while reaching for "t", our other fingers will also start reaching for "h" and "e". Basically, the time taken for traveling to future keys is masked by the time taken for traveling to the current key.

## Then what is the purpose of optimizing a layout?

Less movement overall can still reduce finger strain, though the extent to which a particular layout change can do this varies. As an extreme example, imagine if the spacebar were place at the backtick/tilde position. No doubt your pinkie would not be happy. 

Furthermore, an optimized layout can take into account productivity tasks such as code navigation, program-specific hotkeys, etc. Most existing layouts are very English text / typing test heavy and don't account for other common operations we do with our keyboards. For example, I find that moving my arm to access the arrow keys is very cumbersome -- with layers, such navigation can be placed closer to the keyboard center.


