module VlasiatorMakie

using Vlasiator, StatsBase, Printf
using Vlasiator: AxisUnit, ColorScale
using Makie
using Makie.LaTeXStrings: latexstring

include("typerecipe.jl")
include("fullrecipe.jl")
include("interactive.jl")

export
   vlheatmap, vlslice, vlslices,
   vdfvolume, vdfslice, vdfslices

end
