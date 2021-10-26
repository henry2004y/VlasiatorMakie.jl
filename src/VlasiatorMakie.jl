module VlasiatorMakie

using Vlasiator, StatsBase, Printf

using Makie

include("typerecipe.jl")
include("fullrecipe.jl")
include("interactive.jl")

export
   vlheatmap, vlslice,
   vdfvolume, vdfslice, vdfslices

end
